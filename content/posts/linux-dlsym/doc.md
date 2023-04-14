---
author: "Lambert Xiao"
title: "Linux-dlsym"
date: "2023-04-13"
summary: "dlsym(dynamic link symbol)"
tags: ["linux"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 前言

最近研究c++协程库libco的时候发现，它内部大量运用了dlsym技术，对如connect, sendto, recv, read, write等系统调用做了hook, 从而使得libco能在单线程的情况下调度协程。出与对dlsym技术的学习总结，出了这篇博文


## dlsym概述

dlsym是动态链接库中的一个关键函数，可以通过符号名（Symbol）获取函数指针。定义如下：

```
void *dlsym(void *handle, const char *symbol);
```

其中，handle表示动态链接库的句柄，symbol表示需要查找的符号名。dlsym返回符号名对应的函数指针，如果未找到符号，则返回NULL。

## dlsym使用方法

### dlsym + dlopen

先准备一个libfoo.so

```h
// foo.h
extern "C" void foo();

// foo.cpp
#include <stdio.h>
#include "foo.h"

void foo() {
  printf("you are foo");
}
```

编译动态链接库

```
g++ -fPIC -shared -o libfoo.so foo.cpp -ldl
```

```cpp
// main.cpp
#include <dlfcn.h>
#include <stdio.h>
#include "foo.h"

typedef void* (*foo_func)();
int main() {
  void* handle = dlopen("./libfoo", RTLD_LAZY);
  foo_func foo = (foo_func)dlsym(handle, "foo");
  char* err = dlerror();
  if (err) {
    printf("%s\n", err);
    return 0;
  }

  foo();
}
```

执行命令，可以看到我们通过dlsym这种方式调用到了libfoo.so中的foo函数

```
g++ -std=c++11 -o main main.cpp
LD_PRELOAD=./libfoo.so ./main
```

### dlsym + RTLD_DEFAULT

一般而言，symbol的查找是有先后顺序的，并且可能多个动态链接库里有同一个symbol名称；
比如`echo`这个symbol, 可能在liba.so里有定义，在libc.so里也有定义。对于这种情况，我们可以使用RTLD_DEFAULT。
RTLD_DEFAULT是个特殊的宏，表示在查找symbol的时候，返回第一个查找到的symbol的地址，找到了就不需往别的动态链接库里查找了。

```cpp
#include <stdio.h>
#include <dlfcn.h>

typedef void (*printf_func_ptr)(const char *, ...);

int main() {
  printf_func_ptr printf_ptr = (printf_func_ptr)dlsym(RTLD_DEFAULT, "printf");
  printf_ptr("Hello, world!\n");
  return 0;
}
```

执行后可以发现，我们通过dlsym调用到了系统库里的printf函数

### dlsym + RTLD_NEXT

与RTLD_DEFAULT不同的点在于，RTLD_NEXT表示查找symbol的时候，跳过所在的动态链接库，继续去别的lib中找到symbol的位置，找到了就返回。

这有什么用呢？通过LD_PRELOAD环境变量，可以用来对某些系统调用做hook。看下面例子


```cpp
// hook.cpp

#include <stdio.h>
#include <stdint.h>
#include <dlfcn.h>

#define ENABLE_HOOK_FUNC(name) \
  if (!g_sys_##name) { \
    g_sys_##name = (sys_##name##_t)dlsym(RTLD_NEXT, #name); \
  }

typedef void* (*sys_malloc_t)(size_t size);
static sys_malloc_t g_sys_malloc = NULL;

extern "C" {
void* malloc(size_t size) {
  ENABLE_HOOK_FUNC(malloc);
  printf("invoke malloc hook function\n");
  void *p = g_sys_malloc(size);
  return p;
}
```

编译动态链接库

```
g++ -fPIC -shared -o libhook.so hook.cpp -ldl
```

> 注意点，由于hook.cpp是c++文件，因此必须在需要做hook的函数外面写上`extern "C"`, 否则实际生成的so的方法名不一定是`malloc`

```cpp
// main.cpp

#include <memory>

int main() {
  printf("before malloc\n");
  char* buf = (char*)malloc(sizeof(char));
  if (!buf) {
    printf("malloc error\n");
  }
  printf("after malloc\n");
  return 0;
}
```

通过LD_PRELOAD即可实现对malloc函数的hook

```
g++ -std=c++11 -o main main.cpp
LD_PRELOAD=./libhook.so ./main
```

执行后可以发现，我们通过LD_PRELOAD前置了一个动态链接库，成功地实现了对系统库里的malloc函数进行hook
