---
author: "Lambert Xiao"
title: "C-小知识"
date: "2022-03-06"
summary: "为了在存储的路上深耕，C/C++知识储备不能少"
tags: ["C"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## extern

```
int x; // 这叫声明并定义x
int y = 10; // 这叫声明并定义y

extern int x; // 声明而非定义
extern int y = 10; // 会报错
```

extern它可以应用于一个全局变量，函数或模板声明，说明该符号具有外部链接(external linkage)属性，说白了就是这个符号在这里被声明了，但是会在别处被定义

## 指针问题

判断一个指针是否是合法的指针没有高效的方法，这是C/C++指针问题的根源
