---
author: "Lambert Xiao"
title: "网络-ssdp协议"
date: "2022-06-16"
summary: "基于udp+http协议，在upnp中被使用到"
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
mermaid: true
---

## 简介

ssdp协议是实现upnp的协议之一，它是建立在UDP之上，协议格式类似HTTP。

## 协议流程

### M-SEARCH流程

- 控制端：想要直到网络里当前其余设备的信息
- 多播地址：一个固定的地址，一般监听在 `239.255.255.250:1900`

{{<mermaid>}}
sequenceDiagram
    participant 控制端
    participant 多播地址
    控制端 ->> 多播地址: 发送M-SEARCH请求
    多播地址 ->> 控制端: 响应设备信息
{{</mermaid>}}

> 控制端发送的是UDP的多播包，只发一次，但会有很多地址都收到这个包

### M-SEARCH协议格式

请求：

```
M-SEARCH * HTTP/1.1
S: uuid:ijklmnop-7dec-11d0-a765-00a0c91e6bf6
Host: 239.255.255.250:1900
Man: "ssdp:discover"
ST: ge:fridge
MX: 3
```

响应：

```
HTTP/1.1 200 OK
Cache-Control: max-age= seconds until advertisement expires
S: uuid:ijklmnop-7dec-11d0-a765-00a0c91e6bf6
Location: URL for UPnP description for root device
Cache-Control: no-cache="Ext",max-age=5000ST:ge:fridge
```
