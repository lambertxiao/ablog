---
author: "Lambert Xiao"
title: "什么是NUMA"
date: "2024-02-12"
summary: ""
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# NUMA

今天在学习DPDK的过程中接触到了NUMA，特此记录

## 什么是NUMA

NUMA全称为 `Non-uniform memory access`, 即非一致性内存访问，它是一种计算机内存设计方案，主要用于多处理器的计算机中。但在理解NUMA之前，
我们需要先了解SMP（Symmetric multiprocessing），即对称性多处理；在SMP架构中，CPU和内存的关系如下图所示：

![](https://gist.github.com/assets/34566503/1831f90f-c04c-4177-8bcc-d4334a2d8645)

所有的CPU核心处理器都通过系统总线与内存进行数据交互（中间有Cache层会对数据进行访问加速），这架构很简单对吧，一目了然，但是这个架构存在一个问题，
就是当CPU的核心处理器越来越多时，由于总线在同一时刻只能有一个设备在访问，因此CPU的核心处理器之间会相互争夺总线的使用权，核心越多，
争夺得越激烈，运行效率就越低。

在这种情况下，NUMA诞生了，NUMA的架构其实也很简单，如下

![](https://gist.github.com/assets/34566503/82a95d18-a16f-474b-a64d-96e53ff7d1e0)

NUMA 尝试通过为每个处理器提供单独的内存来解决此问题，从而避免多个处理器尝试寻址同一内存时对性能造成的影响。
NUMA定义了一个叫Node的概念，每一个Node会包含一组CPU的处理器，内存控制器（Memory Controler）和一组内存。CPU的处理器通过内存控制器访问内存。
Node与Node之间是物理上相互连接着的。
Node内的处理器访问Node里的内存，称为local access，Node内的处理器访问其他Node的内存，称为remote access。

## 怎么使用NUMA

经过前面的介绍，我们知道，local access是在一个Node内部发生的，争夺内存控制器的使用权的处理器数量是有限的，因此它必然是很高效的；
我们在编程过程中也要尽量让程序在一个Node内运行，而不要在各个Node间相互调度。在Linux上，提供了一个 `numactl` 的工具可以帮助我们对处理器的numa策略进行配置。

### 显示node的配置

```
numactl -H
```

```
available: 2 nodes (0-1)
node 0 cpus: 0 1 2 3 4 5 6 7 8 9 20 21 22 23 24 25 26 27 28 29
node 0 size: 63822 MB
node 0 free: 20142 MB
node 1 cpus: 10 11 12 13 14 15 16 17 18 19 30 31 32 33 34 35 36 37 38 39
node 1 size: 64507 MB
node 1 free: 19918 MB
node distances:
node   0   1
  0:  10  21
  1:  21  10
```

可以看到，我的机器上被划分了两个Node，并且每个node分配的内存在60GB左右，其中
Node0包含处理器（0 1 2 3 4 5 6 7 8 9 20 21 22 23 24 25 26 27 28 29），
Node1包含（10 11 12 13 14 15 16 17 18 19 30 31 32 33 34 35 36 37 38 39）。
Node Distances是NUMA架构中的节点距离，指的是从一个节点访问另一个节点上的内存所需要付出的代价或延迟。
