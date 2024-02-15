---
author: "Lambert Xiao"
title: "什么是VFIO"
date: "2024-02-12"
summary: ""
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# VFIO

## 什么是VFIO

> VFIO可以简单理解为一个增强版的UIO，上一个文章里提到了UIO的几个不足，不支持DMA，仅支持有限的中断，需要用root访问等，而VFIO就是为了弥补这些不足诞生的。

VFIO也是linux提供的一个用户态驱动框架，使用VFIO能开发用户态驱动。VFIO 允许用户将物理设备直接分配给虚拟机，从而让虚拟机获得接近物理机的性能。（VFIO 可以绕过虚拟化管理程序，直接将虚拟机的 I/O 请求发送到物理设备）

## 为什么要用VFIO

一些应用程序，特别是在高性能计算领域，由于需要很低的延时开销，需要从用户空间直接访问设备。在没有VFIO的时候，有两个选择，

1. 可以选择直接开发内核驱动（复杂又繁琐，稳定性差）
2. 使用UIO框架，但该框架没有IOMMU保护的概念，有限的中断支持，并且需要root权限才能访问PCI配置空间等内容。

VFIO驱动程序框架旨在解决这些问题，取代KVM PCI特定的设备分配代码，并提供比UIO更安全，功能更丰富的用户空间驱动程序环境。

## VFIO被用在哪里

- KVM
- QEMU
- VMware ESXi
- Hyper-V

## 怎么使用

VFIO 使用用户态驱动来实现设备直通。用户态驱动运行在虚拟机的用户空间中，可以直接访问物理设备。

VFIO 的工作流程如下：

1. 用户在虚拟机中安装 VFIO 驱动。
2. 用户将物理设备分配给虚拟机。
3. VFIO 驱动在虚拟机的用户空间中启动。
4. VFIO 驱动访问物理设备。
5. VFIO 提供了一系列 API 来管理设备直通。这些 API 允许用户：
  - 列出可用的物理设备
  - 将物理设备分配给虚拟机
  - 从虚拟机中释放物理设备
  - 配置 VFIO 驱动

## VFIO的组成

### Device（设备）

设备是指要操作的硬件设备，这些设备可以是网卡、显卡、存储控制器等。在VFIO中，设备是通过IOMMU（Input/Output Memory Management Unit）进行管理的。IOMMU是一个硬件单元，它可以把设备的IO地址映射成虚拟地址，为设备提供页表映射，使得设备可以直接通过DMA（Direct Memory Access）方式访问内存。
设备在VFIO中是被隔离和暴露给虚拟机或用户空间程序的关键资源。通过VFIO，设备可以被分配给特定的虚拟机或用户空间程序，以实现设备直通。

### Group（组）

Group是IOMMU能进行DMA隔离的最小硬件单元。一个group可以包含一个或多个device，具体取决于物理平台上硬件的IOMMU拓扑结构，Group是硬件上的划分。这意味着，如果一个设备在硬件拓扑上是独立的，那么它本身就构成一个IOMMU group。而如果多个设备在硬件上是互联的，需要相互访问数据，那么这些设备需要被放到同一个IOMMU group中。在VFIO中，group是设备直通的最小单位。也就是说，当设备直通给一个虚拟机时，group内的所有设备都必须同时直通给该虚拟机。

### Container（容器）

Container是由多个group组成的集合，Container是逻辑上的划分，为了让内部的group能共享某些资源。
虽然group是VFIO的最小隔离单元，但在某些情况下，将多个group组合到一个container中可以提高系统的性能。例如，当多个group需要共享一个页表时，将它们组合到一个container中是有益的。此外，将多个group放入一个container中也方便用户进行管理和控制。

## VFIO在DKDP中的使用

![](https://gist.github.com/assets/34566503/f2a0f43e-696f-43b9-bad0-fe8c90442f0e)

在上面的例子中，PCI设备1和PCI设备2是被分配给客户DPDK应用的两个设备。在主机中，这两个设备都使用内核VFIO驱动程序分配给客户机。在Guest系统中，当我们将设备分配给DPDK应用程序时，我们可以使用VFIO、VFIO no-iommu mode、UIO三种模式。然而，只有当我们使用通用VFIO驱动程序（需要vIOMMU）分配设备时，我们才能获得安全分配的设备。通过“UIO”或“VFIO no-iommu模式”分配设备是不安全的。
