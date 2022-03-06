---
author: "Lambert Xiao"
title: "Golang-内存分配"
date: "2022-03-06"
summary: "mcache, mcentral, mheap"
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# golang 内存分配

golang抛弃了传统的内存分配方式，改为自主管理。这样可以自主地实现更好的内存使用模式，比如内存池、预分配等等。而且不会每次内存分配都需要进行系统调用。

核心思想：核心思想就是把内存分为多级管理，从而降低锁的粒度。它将可用的堆内存采用二级分配的方式进行管理：每个线程都会自行维护一个独立的内存池，进行内存分配时优先从该内存池中分配，当内存池不足时才会向全局内存池申请，以避免不同线程对全局内存池的频繁竞争。

## 基础概念

go在程序启动的时候，会向操作系统申请一块内存，切成小块后自己管理；

申请到的内存分成三个区域：

![](../golang内存分区.jpg)

arena区域就是我们所谓的堆区，Go动态分配的内存都是在这个区域，它把内存分割成8KB大小的页，一些页组合起来称为mspan。

bitmap区域标识arena区域哪些地址保存了对象，并且用4bit标志位表示对象是否包含指针、GC标记信息。bitmap中一个byte大小的内存对应arena区域中4个指针大小（指针大小为 8B ）的内存，所以bitmap区域的大小是512GB/(4*8B)=16GB。

spans区域存放mspan的指针，每个指针对应一页

### 内存管理单元

mspan：Go中内存管理的基本单元，是由一片连续的8KB的页组成的大块内存。
一句话概括：mspan是一个包含起始地址、mspan规格、页的数量等内容的双端链表。

每个mspan按照它自身的属性Size Class的大小分割成若干个object，每个object可存储一个对象。并且会使用一个位图来标记其尚未使用的object。属性Size Class决定object大小，而mspan只会分配给和object尺寸大小接近的对象。


