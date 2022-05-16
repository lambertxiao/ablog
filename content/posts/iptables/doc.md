---
author: "Lambert Xiao"
title: "iptables和netfilter"
date: "2022-05-16"
summary: "iptables, netfilter, 5链3表"
tags: ["iptables"]
categories: ["iptables"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

iptables其实不是真正的防火墙，我们可以把它理解成一个客户端代理，用户通过iptables这个代理，将用户的安全设定执行到对应的”安全框架”中，这个”安全框架”才是真正的防火墙，这个框架的名字叫netfilter

netfilter才是防火墙真正的安全框架（framework），netfilter位于内核空间。


## Netfilter

Netfilter是Linux操作系统核心层内部的一个数据包处理模块，它具有如下功能：

1. 网络地址转换(Network Address Translate)
2. 数据包内容修改
3. 数据包过滤的防火墙功能

## iptables

iptables里有三个概念需要先明确一下

### 规则

通俗来讲，规则定义了 “如果某个数据包复合这样的规则，就这么处理它”。规则存储在内核空间的信息包过滤表中，这些规则分别指定了源地址、目的地址、传输协议（如TCP、UDP、ICMP）和服务类型（如HTTP、FTP和SMTP）等。当数据包与规则匹配时，iptables就根据规则所定义的方法来处理这些数据包，如放行（accept）, 拒绝（reject）, 丢弃（drop）

#### 匹配条件

- 源地址Source IP

- 目标地址 Destination IP

- 扩展匹配条件

    - 源端口Source Port
    - 目标端口Destination Port

#### 处理动作

- ACCEPT：允许数据包通过。
- DROP：直接丢弃数据包，不给任何回应信息，这时候客户端会感觉自己的请求泥牛入海了，过了超时时间才会有反应。
- REJECT：拒绝数据包通过，必要时会给数据发送端一个响应的信息，客户端刚请求就会收到拒绝的信息。
- SNAT：源地址转换，解决内网用户用同一个公网地址上网的问题。
- MASQUERADE：是SNAT的一种特殊形式，适用于动态的、临时会变的ip上。
- DNAT：目标地址转换。
- REDIRECT：在本机做端口映射。
- LOG：在/var/log/messages文件中记录日志信息，然后将数据包传递给下一条规则，也就是说除了记录以外不对数据包做任何其他操作，仍然让下一条规则去匹配

### 链

有了规则后，那么数据包是如何去匹配规则的？在这里引出了链

![](../1.png)

当一个数据包从网卡到达内核空间时，它需要经历一道道关卡。netfilter定义了五道关卡，分别是

- prerouting
- input
- forward
- postrouting
- output

从图上可以看出，一个数据包根据内容的不同，不一定会将所有的关卡都走一遍。

有人会问，每个关卡看着都像一个单节点，为什么这里要称之为链呢？其实，当数据包进入关卡后，需要匹配关卡内定义的规则，而一个关卡是可以定义多条规则的，当我们把这些规则都串到一个链表上的时候，就形成了链。

![](../2.png)


### 表

上面可以看出，链上其实就是一系列的规则，且这些规则有些都很相似，比如，A类规则都是对IP或者端口的过滤，B类规则是修改报文。
因此，iptables定义了表的概念，一个表就是具有相同功能的规则的集合。iptables预定义了4种表，如下：


| 表名 | 功能 | 对应内核模块 | 可以使用的链 |
| - | - | - | - |
| filter | 负责过滤 | iptables_filter | input, forward, output |
| nat | 网络地址转换 | ptable_nat | prerouting, output, postrouting |
| mangle | 拆解报文，做出修改，并重新封装 | iptable_mangle | prerouting, input, forward, output, postrouting |
| raw | 关闭nat表上启用的连接追踪机制 | iptable_raw | prerouting, output |

表的优先级: 

raw –> mangle –> nat –> filter

### 完整流程

![](../3.png)
