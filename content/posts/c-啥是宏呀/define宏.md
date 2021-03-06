---
author: "Lambert Xiao"
title: "C-啥是宏"
date: "2022-03-06"
summary: "宏在C中真的是无所不在了吧"
tags: ["C"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# define的用法

define是C语言中提供的宏定义命令，其主要目的是在编程时提供一定的方便。

## 简单的宏定义

> define <宏名> <字符串>

```c
#define PI 3.14
```

## 带参数的宏定义

> #define <宏名> (<参数表>) <宏体>

```c
#define INC(a) ((a) = ((a)+1))
```

## 宏替换的时机

在程序中出现的是宏名，在该程序被编译前，先将宏名用被定义的字符串替换，这称为宏替换，替换后才进行编译，宏替换是简单的替换。
宏替换由预处理器完成。预处理器将源程序文件中出现的对宏的引用展开成相应的宏定义，经过预处理器处理的源程序与之前的源程序有所有不同，在这个阶段所进行的工作只是纯粹的替换与展开，没有任何计算功能。
