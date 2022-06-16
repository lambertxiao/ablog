---
author: "Lambert Xiao"
title: "Linux-strace"
date: "2022-06-16"
summary: "查看系统调用的神器"
tags: ["linux"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

strace是linux上的一个可以查看执行命令对应的系统调用的工具。

## 使用场景

1. 跟踪命令底下执行的系统调用，无需借助内核及程序日志
2. 定位命令执行失败的原因

## 使用方式

### 基本用法

举个例子，以 `echo "a" > a.txt` 命令为例，可以直接在命令前面加上strace后执行，

`strace echo "a" > a.txt`

```shell
...
fstat(1, {st_mode=S_IFREG|0664, st_size=0, ...}) = 0
write(1, "a\n", 2)                      = 2
close(1)                                = 0
...
```

以上输出精简了部分内容，可以看到`echo "a" > a.txt`对应了几个系统调用，先fstat判断文件是否存在，再通过write将内容写入文件，最后关闭文件。

### 统计每个系统调用

`strace -c dd if=/dev/zero of=big.dat bs=1024k count=10`, 使用dd生成一个10M的文件

加上`-c` 参数会统计每一系统调用的所执行的时间,次数和出错的次数等。

```
10+0 records in
10+0 records out
10485760 bytes (10 MB, 10 MiB) copied, 0.0104206 s, 1.0 GB/s
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 86.41    0.006694         514        13           write
  9.80    0.000759          58        13           read
  2.79    0.000216          12        18        12 openat
  0.81    0.000063           7         9           close
  0.19    0.000015           3         4           fstat
  0.00    0.000000           0         1           lseek
  0.00    0.000000           0         9           mmap
  0.00    0.000000           0         4           mprotect
  0.00    0.000000           0         1           munmap
  0.00    0.000000           0         3           brk
  0.00    0.000000           0         3           rt_sigaction
  0.00    0.000000           0         6           pread64
  0.00    0.000000           0         1         1 access
  0.00    0.000000           0         2           dup2
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2         1 arch_prctl
------ ----------- ----------- --------- --------- ----------------
100.00    0.007747                    90        14 total
```

通过上面的统计信息可以发现，该命令执行期间主要在执行read和write的系统调用，并且write操作占了大部分的时间

### 指定跟踪的系统调用类型

- `-e trace=process`

    跟踪涉及过程管理的所有系统调用。这对于观察进程的派生，等待和执行步骤很有用。

- `-e trace=network`

    跟踪所有与网络相关的系统调用。

- `-e trace=signal`

    跟踪所有与信号相关的系统调用。

- `-e trace=ipc`

    跟踪所有与IPC相关的系统调用。
