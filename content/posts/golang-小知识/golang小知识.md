---
author: "Lambert Xiao"
title: "Golang-小知识"
date: "2022-03-06"
summary: "面试前总得背一背吧"
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# Golang小知识

## context是干嘛的

context用于停止goroutine，协调多个goroutine的取消，设置超时取消等等。
基于channel和select来实现停止，另外还可以用context在不同的goroutine中传递数据。其中停止goroutine是context的核心

## new和make的区别？

- new是用来创建一个某个类型对象的，并返回指向这个类型的零值的指针。
- make是用来创建slice，map，chanel的，并返回引用

> 指针变量存储的是另一个变量的地址, 引用变量指向另外一个变量。

## 数组与切片

- 数组定长，不可改变，值传递
- 切片变长，可改变，地址传递

## channel特性

- 给一个 nil channel 发送数据，造成永远阻塞
- 从一个 nil channel 接收数据，造成永远阻塞
- 给一个已经关闭的 channel 发送数据，引起 panic
- 从一个已经关闭的 channel 接收数据，如果缓冲区中为空，则返回一个零值
- 无缓冲的channel是同步的，而有缓冲的channel是非同步的

## 进程、线程、协程之间的区别

进程是资源的分配和调度的一个独立单元，而线程是CPU调度的基本单元

## map的底层结构

bucket桶，链表，哈希函数，key，装载因子，扩容，用链表法解决哈希冲突；
当向桶中添加了很多 key，造成元素过多，或者溢出桶太多，就会触发扩容。扩容分为等量扩容和 2 倍容量扩容。扩容后，原来一个 bucket 中的 key 一分为二，会被重新分配到两个桶中。扩容过程是渐进的，主要是防止一次扩容需要搬迁的 key 数量过多，引发性能问题

## slice的底层结构

```go
type Slice struct {
    ptr unsafe.Pointer 
    len int
    cap int
}
```

当插入时，如果len不大于cap，不会产生新的slice；如果len大于cap，则会创建一个新的slice，并将老的slice元素copy过去

## interface底层结构

## 反射机制
