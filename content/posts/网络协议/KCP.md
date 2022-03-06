---
author: "Lambert Xiao"
title: "啥是KCP协议？"
date: "2022-03-06"
summary: "TCP退下，让我来！"
tags: ["网络知识"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# KCP

## 相对于TCP的改进

1. RTO不翻倍

RTO(Retransmission-TimeOut)即重传超时时间,TCP是基于ARQ协议实现的可靠性，KCP也是基于ARQ协议实现的可靠性，但TCP的超时计算是RTO*2，而KCP的超时计算是RTO*1.5，也就是说假如连续丢包3次，TCP是RTO*8，而KCP则是RTO*3.375，意味着可以更快地重新传输数据。通过4字节ts计算RTT(Round-Trip-Time)即往返时延，再通过RTT计算RTO，ts(timestamp)即当前segment发送时的时间戳。

2. 选择性重传

TCP中实现的是连续ARQ协议，再配合累计确认重传数据，只不过重传时需要将最小序号丢失的以后所有的数据都要重传，而KCP则只重传真正丢失的数据。

3. 快速重传

与TCP相同，都是通过累计确认实现的，发送端发送了1，2，3，4，5几个包，然后收到远端的ACK：1，3，4，5，当收到ACK = 3时，KCP知道2被跳过1次，收到ACK = 4时，知道2被跳过了2次，此时可以认为2号丢失，不用等超时，直接重传2号包，大大改善了丢包时的传输速度。1字节cmd = 81时，sn相当于TCP中的seq，cmd = 82 时，sn相当于TCP中的ack。cmd相当于WebSocket协议中的openCode，即操作码。

4. 非延迟ACK

TCP在连续ARQ协议中，不会将一连串的每个数据都响应一次，而是延迟发送ACK，即上文所说的UNA模式，目的是为了充分利用带宽，但是这样会计算出较大的RTT时间，延长了丢包时的判断过程，而KCP的ACK是否延迟发送可以调节。

5. UNA + ACK

UNA模式参考特征2和特征4，ACK模式可以参考特征3。4字节una表示cmd = 81时，当前已经收到了小于una的所有数据。

6. 非退让流控

在传输及时性要求很高的小数据时，可以通过配置忽略上文所说的窗口协议中的拥塞窗口机制，而仅仅依赖于滑动窗口。2字节wnd与TCP协议中的16位窗口大小意义相同，值得一提的是，KCP协议的窗口控制还有其它途径，当cmd = 83时，表示询问远端窗口大小，当cmd = 84时，表示告知远端窗口大小。

4字节conv表示会话匹配数字，为了在KCP基于UDP实现时，让无连接的协议知道哪个是哪个，相当于WEB系统HTTP协议中的SessionID。

1字节frg表示拆数据时的编号，4字节len表示整个数据的长度，相当于WebSocket协议中的len。

