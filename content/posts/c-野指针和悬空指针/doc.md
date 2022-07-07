---
author: "Lambert Xiao"
title: "c-野指针和悬空指针"
date: "2022-07-07"
summary: ""
tags: ["C"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 野指针

看代码

```
void *p; // 此时p为野指针
```

> “野指针”可能指向任意内存段，因此它可能会损坏正常的数据，也有可能引发其他未知错误

正确做法

```
void *p = NULL
```

## 悬空指针

看代码

```
void *p = malloc(size);
free(p);
// p为悬空指针了
```

> free(p) 之后，p指针仍然指向之前分配的内存，有可能会引发不可预知的错误

正确做法

```
void *p = malloc(size);
free(p);
p = NULL
```