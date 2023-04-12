---
author: "Lambert Xiao"
title: "如何使用mmap读写文件"
date: "2023-04-09"
summary: "读写文件新姿势"
tags: ["零拷贝"]
categories: ["零拷贝"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

mmap(memory map) 是一种将磁盘上的文件映射到内存中的方法，它可以帮助程序更高效地访问磁盘文件。

## 原理

> 参见：https://www.man7.org/linux/man-pages/man2/mmap.2.html

```c
#include <sys/mman.h>

void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
int munmap(void *addr, size_t length);
```

`mmap()`函数会创建一个映射，将fd对应的文件内容映射到addr位置。如果 addr 为 NULL，则内核选择与页面对齐的地址创建映射。如果 addr 不为 NULL，内核会选择一个就近的位置进行映射 (但总是高于或等于 /proc/sys/vm/mmap_min_addr 指定的值), 并尝试在该位置创建映射。如果已存在另一个映射，则内核选择一个新地址。映射的地址作为调用的结果返回。在 mmap() 调用返回后，可以立即关闭文件描述符 fd，而不会破坏映射。

prot参数用户描述了映射所需的内存保护 (且必须不与其他文件的打开模式冲突)。

- PROT_EXEC Pages may be executed.
- PROT_READ Pages may be read.
- PROT_WRITE Pages may be written.
- PROT_NONE Pages may not be accessed.

flags参数常见的有这2种：

- MAP_SHARED 创建一个共享的映射，在该映射上的更新能被其他进程感知到
- MAP_PRIVATE 创建一个私有的，copy-on-write的映射，在该映射上的改动对于其他进程不可见

## 示例代码

```c++
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#define PAGE_SIZE 4096

int main() {
  // 打开磁盘文件
  int fd = open("test.txt",  O_RDWR);
  if (fd < 0) {
    perror("open");
    return -1;
  }

  // 映射磁盘文件到内存中
  char* addr = (char*)mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (addr == MAP_FAILED) {
    perror("mmap");
    close(fd);
    return -1;
  }

  printf("磁盘文件内容：%s\n", addr);

  *(addr + 5) = 'a';

  int ret = munmap(addr, PAGE_SIZE);
  if (ret == -1) {
    perror("munmap");
  }
  close(fd);
  return 0;
}
```

首先我们准备一个`test.txt`，在open完文件后，将文件内容通过mmap映射到内存中，然后在内存中进行修改，使用mumap退出映射，查看文件的内容。
