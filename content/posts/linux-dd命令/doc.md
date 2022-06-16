---
author: "Lambert Xiao"
title: "Linux-dd命令"
date: "2022-06-16"
summary: "生成文件的好用工具"
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

dd 命令用于读取、转换并输出数据，听着很抽象吧，实际用起来很简单，看以下例子

## 基本使用方法

```bash
dd if=<inputDevice> of=<outputDevice>
```

dd的原理是从if指定的文件或设备中，读取数据，再输出到of指定的文件或设备中

### 生成一个10M的空内容文件

```
dd if=/dev/zero of=test.dat bs=1024k count=10
```

命令执行后，会在当前文件夹得到一个文件名为test.dat且文件大小为10M的文件，`bs=1024k` 指定一次往输出端输出1M数据，`count=10` 指定共往输出端输出10次

### 生成随机内容文件

```
dd if=/dev/random of=test.dat bs=1024k count=10
```

### 从文件中读取1M内容

```
dd if=test.dat of=/dev/null bs=1024k count=1
```

### 批量生成文件

```
seq 10 | xargs -i dd if=/dev/zero of={}.dat bs=1024k count=1
```

以上命令会生成10个1M大小的文件

```
total 10248
drwxrwxr-x  2 ubuntu ubuntu    4096 Jun 16 11:13 .
drwxr-xr-x 12 ubuntu ubuntu    4096 Jun 16 11:13 ..
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 10.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 1.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 2.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 3.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 4.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 5.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 6.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 7.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 8.dat
-rw-rw-r--  1 ubuntu ubuntu 1048576 Jun 16 11:13 9.dat
```
