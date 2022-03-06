---
author: "Lambert Xiao"
title: "UDP协议"
date: "2022-03-06"
summary: "觉得TCP太慢了，何不试试我？"
tags: ["网络知识"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# UDP

> UDP是一种不可靠的不面向连接的传输层协议

## 报文结构

- 源端口

- 目标端口

- 长度

- 校验和

- 报文内容

> UDP仅仅只是在IP数据报上加了端口，用来实现多路复用，多路分解
