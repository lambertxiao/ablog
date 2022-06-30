---
author: "Lambert Xiao"
title: "网络-NAT打洞"
date: "2022-06-24"
summary: "洞次打次，洞次打次"
tags: ["网络"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 抛砖引玉

想象一个场景，AB两个客户端处在不同的内网里，如何能让A和B相互能访问到彼此？

我们知道，当A运行在内网里，假设A的内网地址为（192.160.10.1）, 访问公网上一个Server时，站在Server的角度来看A的请求IP，可以发现并不是A的内网地址，为什么呢？因为从A到S的过程中，其实经过了一层NAT，NAT记录一层映射关系，

A的内网IP和端口 - 出口的IP和端口

## 问题

### 谁来执行NAT

路由器？

### 打洞成功率
