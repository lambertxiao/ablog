---
author: "Lambert Xiao"
title: "怎么使用valgrind诊断内存问题"
date: "2023-03-22"
summary: "让valgrind为你的程序保驾护航"
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

Valgrind是一个非常有用的开源工具集，主要用于Linux和其他类Unix操作系统上的代码调试、跟踪内存泄漏、性能分析以及各种内存错误等问题的诊断和解决。

Valgrind包含了多个工具，这些工具可以检测出内存泄漏、数组越界访问、使用未初始化的内存、传递未初始化的变量等等问题。同时，它还可以提供程序的时间性能的分析，以及调试信息的输出。

> 作为C, C++开发者，用了valgrind，妈妈再也不用担心你写的代码有内存泄漏了

## 怎么用

valgrind的用法非常简单，仅需要在你的执行命令前加上valgrind

```
$ valgrind ./your-program [your-program params]
```

> 如果你的程序是使用gcc编译的，在编译的时候加上`-g`选项，valgrind就可以给你更多的与错误相关的信息

## 看懂valgrind的错误提示

valgrind能诊断出来如下几种错误：

- Invalid read
- Invalid write
- Conditional jumps
- Syscall param points to unadressable bytes
- Invalid free 
- Mismatched free
- Fishy values

### Invalid write

举个例子

```c++
int main(void) {
  char *str = malloc(sizeof(char) * 10);
  int i = 0;

  while (i < 15) {
    str[i] = '\0';
    i = i + 1;
  }
  free(str);
  return (0);
}
```

上面例子里, str指向了一块大小为10字节的内存，但是却在while循环里，设置了超过10字节的内容

```
$ gcc main.c -g
$ valgrind ./a.out
==18332== Memcheck, a memory error detector
==18332== Copyright (C) 2002-2017, and GNU GPL\'d, by Julian Seward et al.
==18332== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==18332== Command: ./a.out
==18332==
==18332== Invalid write of size 1
==18332==    at 0x400553: main (test.c:7)
==18332==  Address 0x521004a is 0 bytes after a block of size 10 alloc\'d
==18332==    at 0x4C2EB6B: malloc (vg_replace_malloc.c:299)
==18332==    by 0x400538: main (test.c:3)
==18332==
==18332==
==18332== HEAP SUMMARY:
==18332==     in use at exit: 0 bytes in 0 blocks
==18332==   total heap usage: 1 allocs, 1 frees, 10 bytes allocated
==18332==
==18332== All heap blocks were free'd -- no leaks are possible
==18332==
==18332== For counts of detected and suppressed errors, rerun with: -v
==18332== ERROR SUMMARY: 5 errors from 1 contexts (suppressed: 0 from 0)
```

“Invalid write” 意味着我们的程序将数据写到了不该写入的地方

### Invalid read

```c++
int main(void) {
  int i;
  int *ptr = NULL;

  i = *ptr;
  return (0);
}
```

上面的代码将未初始化的指针ptr解引用，使用valgrind一起运行这段代码，会得到如下的错误

```
==26212== Invalid read of size 4
==26212==    at 0x400497: main (test.c:8)
==26212==  Address 0x0 is not stack\'d, malloc\'d or (recently) free\'d
```

### Conditional jumps

```c++
int main(void) {
  int i;
  if (i == 0) {
    my_printf("Hello\n");
  }
  return (0);
}
```

使用valgrind诊断后，它会告诉你使用了会初始化的值来作为条件跳转

```
==28042== Conditional jump or move depends on uninitialised value(s)
==28042==    at 0x4004E3: main (test.c:5)
```

### Syscall param points to unadressable bytes

```c++
int main(void) {
  int fd = open("test", O_RDONLY);
  char *buff = malloc(sizeof(char) * 3);
  free(buff);
  read(fd, buff, 2);
}
```

如上所示，buff所指向的内存在被free后，又被用来作为读取，此时valgrind就要敲你了

```
==32002== Syscall param read(buf) points to unaddressable byte(s)
==32002==    at 0x4F3B410: __read_nocancel (in /usr/lib64/libc-2.25.so)
==32002==    by 0x400605: main (test.c:11)
==32002==  Address 0x5210040 is 0 bytes inside a block of size 3 free\'d
==32002==    at 0x4C2FD18: free (vg_replace_malloc.c:530)
==32002==    by 0x4005EF: main (test.c:10)
==32002==  Block was alloc\'d at
==32002==    at 0x4C2EB6B: malloc (vg_replace_malloc.c:299)
==32002==    by 0x4005DF: main (test.c:8)
```

### Invalid free

```c++
int main(void) {
  char *buff = malloc(sizeof(char) * 54);

  free(buff);
  free(buff);
  return (0);
}
```

这也是个很经典的内存释放问题，一个内存被多次释放，valgrind又要敲你了

```
==755== Invalid free() / delete / delete[] / realloc()
==755==    at 0x4C2FD18: free (vg_replace_malloc.c:530)
==755==    by 0x400554: main (test.c:10)
==755==  Address 0x5210040 is 0 bytes inside a block of size 54 free\'d
==755==    at 0x4C2FD18: free (vg_replace_malloc.c:530)
==755==    by 0x400548: main (test.c:9)
==755==  Block was alloc\'d at
==755==    at 0x4C2EB6B: malloc (vg_replace_malloc.c:299)
==755==    by 0x400538: main (test.c:7)
```

### Mismatched free

```c++
int main() {
 char* p1 = (char*)malloc(sizeof(char)*4);
 delete p1;

 char* p2 = new char;
 free(p2);

 return 0;
}
```

用new分配的内存，用了free来释放（理应用delete);
用malloc分配的内存，用了delete来释放（理应用free）

```
==3281== Mismatched free() / delete / delete []
==3281==    at 0x4C2A51D: operator delete(void*) (vg_replace_malloc.c:586)
==3281==    by 0x400771: main (in /root/workspace/cpp/main)
==3281==  Address 0x5a02040 is 0 bytes inside a block of size 4 alloc'd
==3281==    at 0x4C28F73: malloc (vg_replace_malloc.c:309)
==3281==    by 0x400761: main (in /root/workspace/cpp/main)
==3281==
==3281== Mismatched free() / delete / delete []
==3281==    at 0x4C2A06D: free (vg_replace_malloc.c:540)
==3281==    by 0x40078B: main (in /root/workspace/cpp/main)
==3281==  Address 0x5a02090 is 0 bytes inside a block of size 1 alloc'd
==3281==    at 0x4C29593: operator new(unsigned long) (vg_replace_malloc.c:344)
==3281==    by 0x40077B: main (in /root/workspace/cpp/main)
```

### Fishy values

```c++
int main() {
 int size = -10;
 char* p1 = (char*)malloc(sizeof(char)*size);

 return 0;
}
```

上面的程序中，不小心将需要malloc的内存大小设置为负数，valgrind可以帮我检测出来

```
==3378== Argument 'size' of function malloc has a fishy (possibly negative) value: -10
==3378==    at 0x4C28F73: malloc (vg_replace_malloc.c:309)
==3378==    by 0x400698: main (in /root/workspace/cpp/main)
```
