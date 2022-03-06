---
author: "Lambert Xiao"
title: "未来传输协议之星-QUIC"
date: "2022-03-06"
summary: "我其实是个缝合怪，UDP + TLS + HTTP/2"
tags: ["网络知识"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# Quic

> QUIC融合了包括TCP，TLS，HTTP/2等协议的特性，但基于UDP传输。

## QUIC 的设计目的

- 降低了连接建立时延
- 改进了握手控制
- 多路复用

    同一条 QUIC 连接上可以创建多个 stream，处理上层应用的不同请求

- 避免线头阻塞
- 前向纠错
- 连接迁移
- 默认使用TLS 1.3作为全链路安全

## Quic术语

- 数据包（Packet）：QUIC 协议中一个完整可处理的单元，可以封装在 UDP 数据报（datagram）中。多个 QUIC 数据包（packets）可以封装在一个 UDP 数据报（datagram）中。

- 帧（Frame）：QUIC 数据包（packet）的有效载荷（payload）。

- 端点（Endpoint）：在 QUIC 连接中生成、接收和处理 QUIC 数据包（packets）

    - 客户端（Client）: 创建 QUIC 连接的端点。

    - 服务端（Server）: 接收 QUIC 连接的端点。

- 地址（Address）：未经限定使用时，表示网络路径一端的 IP 版本、IP 地址和 UDP 端口号的元组。

- 连接 ID（Connection ID）： 用于标识端点 QUIC 连接的一种标识符。每个端点（endpoint）为其对端（peer）选择一个或多个连接 ID，将其包含在发送到该端点的数据包（packets）中。这个值对 peer 不透明。

- 流（Stream）：QUIC 连接中有序字节的单向（unidirectional）或双向（bidirectional）通道。一个 QUIC 连接可以同时携带多个流。

- 应用程序（Application）：使用 QUIC 发送或者接收数据的实体。



## Quic的设计

QUIC 同样是一个可靠的协议，它使用 Packet Number 代替了 TCP 的 sequence number，并且每个 Packet Number 都严格递增，也就是说就算 Packet N 丢失了，重传的 Packet N 的 Packet Number 已经不是 N，而是一个比 N 大的值。而

但是单纯依靠严格递增的 Packet Number 肯定是无法保证数据的顺序性和可靠性。QUIC 又引入了一个 Stream Offset 的概念。

- QUIC 最基本的传输单元是 Packet

    - PacketNumber

    - StreamOffset

- Stream 是有序序列的字节

- Ack Delay 时间

    - 通过 window_update 帧告诉对端自己可以接收的字节数，这样发送方就不会发送超过这个数量的数据

    - 通过 BlockFrame 告诉对端由于流量控制被阻塞了，无法发送数据

- 基于 stream 和 connecton 级别的流量控制

## 没有队头阻塞的多路复用

在一条 QUIC 连接上可以并发发送多个 HTTP 请求 (stream)。但是 QUIC 的多路复用相比 HTTP2 有一个很大的优势。

QUIC 一个连接上的多个 stream 之间没有依赖。这样假如 stream2 丢了一个 udp packet，也只会影响 stream2 的处理。不会影响 stream2 之前及之后的 stream 的处理。

这也就在很大程度上缓解甚至消除了队头阻塞的影响。

## 连接过程

QUIC 的连接过程
在 client 端本地没有任何 server 端信息的时候，是无法做到 0RTT 的，下面先来梳理一下 client 首次和 server 通信的流程：

首次连接

0. server 生成一个质数 [公式] 和一个整数 [公式] ，其中 [公式] 是 [公式] 的一个生成元，同时随机生成一个数 [公式] 作为私钥，并计算出公钥 [公式] = [公式]，将 [公式] 三元组打包成 [公式] ，等待 client 连接

1. client 首次发起连接，简单发送 [公式] 给 server

2. server 将已经生成好的 [公式] 返回给 client

3. client 随机生成一个数 [公式]作为自己的私钥，并根据 [公式] 中的 [公式] 和 [公式] 计算出公钥 [公式]

4. client 计算通信使用的密钥 [公式]

5. client 用 [公式] 加密需要发送的业务数据，并带上自己的公钥 [公式] 一起发送给 server

6. server 计算 [公式]，根据笛福赫尔曼密钥交换的原理可以证明两端计算的 [公式]是一样的

7. 这里不能使用 [公式] 作为后续通讯的密钥（下面解释），server 需要生成一个新的私钥 [公式] ，并计算新公钥 [公式] ，然后计算新的通讯密钥 [公式]

8. server 用 [公式] 加密需要返回的业务数据，并带上自己的新公钥 [公式] 一起发送给 client

9. client 根据新的 server 公钥计算通讯密钥 [公式] ，并用 [公式] 解密收到的数据包

10. 之后双方使用 [公式] 作为密钥进行通讯，直到本次连接结束

可以看到，首次连接的时候，在第 3 步时，就已经开始发送实际的业务数据了，而第 1 步和第 2 步正好一去一回花费了 1RTT 时间，所以，首次连接的成本是 1RTT


非首次连接

client 在首次连接后，会把 server 的 [公式] 存下，之后再次发起连接时，因为已经有 [公式] 了，可以直接从上面的第 3 步开始，而这一步已经可以发送业务数据了，所以，非首次连接时，QUIC 可以做到 0RTT

K1 存在的必要性
为什么要再生成一个[公式] ，不能直接用 [公式] 作为后续通讯的密钥？

server 的 [公式] 是静态配置的，是可以长期使用的，其 [公式] 和 [公式] 是提前生成计算好的，为了等待后续 client 连接时计算 [公式] ，[公式] 是不能被销毁的。

想想上面提到的前向安全性，如果攻击者事先记录下了所有通讯过程中的数据包，而后续 server 的 [公式] 泄漏，那就可以根据公开的 [公式] 算出 [公式] ，这样后续的通讯内容就全都可以解密了。而 [公式] 是由双方动态生成的公私钥对计算得来的，最迟在通讯结束后，双方的临时公私钥对就会销毁，从根本上杜绝了泄漏的可能。

换句话说，使用 [公式] 作为通讯密钥，未来万一静态配置在 server 的私钥泄漏，那 [公式] 也就泄漏了，所有历史消息都将泄漏；使用 [公式] 作为通讯密钥，双方私钥在短时间内就会被销毁， [公式] 不会泄漏，历史消息的安全性就得到了保障。

