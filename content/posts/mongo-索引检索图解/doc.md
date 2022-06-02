---
author: "Lambert Xiao"
title: "MongoDB索引检索图解"
date: "2022-05-07"
summary: "亿点点图"
tags: ["mongo"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 前提

> mongodb的索引是通过B+树来实现的

db.test表里插入记录，同时为字段a建立索引

```
db.test.ensureIndex({a: 1})
```

## 等值检索

```
db.test.find({a: 3})
```

![](../1.png)

## 范围查询

```
db.test.find({a: {$gte: 6}})
```

![](../2.png)

## 分页查询

```
db.test.find({a: {$gte: 6}}).skip(2).limit(1)
```

![](../3.png)

## 排序的分页查询

```
db.test.find({a: {$gte: 6}}).sort({a: -1}).skip(2).limit(1)
```

![](../4.png)

## $ne查询

```
db.test.find({a: {$ne: 3}}).limit(5)
```

![](../5.png)

## 复合索引查询

```
db.test.ensureIndex({a: 1, b: 1})
db.test.find({a: 5}).sort({b: -1}).limit(1)
```

![](../6.png)
