---
author: "Lambert Xiao"
title: "Linux系统上的网络抓包"
date: "2022-03-06"
summary: "tcpdump、tshark、editcap、wireshark"
tags: ["抓包"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# Linux系统上的网络抓包

## 涉及工具

* tcpdump

    tcpdump可监听某个网卡的数据包, 并可指定过滤条件查看满足条件的数据包

* tshark

    命令行分析抓包文件, 一般用于当抓到的数据包文件过于庞大不易于拉回本地环境分析时, 可在服务器上简单分析并生成分析视图

* editcap

    可用于按条件拆分抓包文件, 一般用于将一个庞大的数据包拆分成多个小文件, 加快分析速度

* wireshark

    图形化分析抓包文件


## 基本命令

### tcpdump

```
tcpdump -i eth0 port 443
```

抓取eth0网卡上, 使用443端口通信的网络包

```
tcpdump -i eth0 port 443 -w net.pcap
```

抓包的同时, 写入文件, `pcap`是抓包文件的常用格式, 可被wireshark识别

```
tcpdump -r net.pcap
```

以文本的格式打开抓包文件, 但由于网络数据包的量特别大,基本上我们不会查看原始抓包文件, 而是利用工具分析抓包文件,生成报告

### editcap

```
editcap net.pcap output.pcap -i 60
```

将抓包文件按一分钟拆分多个小文件, 小文件会在当前目录下生成, `output.pcap` 指定小文件的输出名

```
editcap net.pcap output.pcap -c 1000
```

将抓包文件按每1000个包的大小拆分

### tshark

```
tshark -n -q -r net.pcap -z "io,stat,0,tcp.flags.syn == 1 && tcp.flags.ack == 0,tcp.flags.reset == 1 && tcp.flags.ack == 0,tcp.analysis.retransmission,tcp.analysis.lost_segment,tcp.analysis.out_of_order"
```

指定一个抓包文件，输出统计信息, `-z` 指定输出的列， 输出结果大致如下, 会按列输出指定的过滤条件的包的数量以及大小：

```
=====================================================================================================================================
| IO Statistics                                                                                                                     |
|                                                                                                                                   |
| Interval size:  2226.2 secs (dur)                                                                                                 |
| Col 1: Frames and bytes                                                                                                           |
|     2: tcp.flags.syn == 1 && tcp.flags.ack == 0                                                                                   |
|     3: tcp.flags.reset == 1 && tcp.flags.ack == 0                                                                                 |
|     4: tcp.analysis.retransmission                                                                                                |
|     5: tcp.analysis.lost_segment                                                                                                  |
|     6: tcp.analysis.out_of_order                                                                                                  |
|-----------------------------------------------------------------------------------------------------------------------------------|
|                    |1                  |2                |3                |4                 |5                |6                |
| Interval           | Frames |   Bytes  | Frames |  Bytes | Frames |  Bytes | Frames |  Bytes  | Frames |  Bytes | Frames |  Bytes |
|-----------------------------------------------------------------------------------------------------------------------------------|
|     0.0 <> 83831.2 | 182425 | 58211981 |   3790 | 280362 |   3526 | 209742 |  11786 | 4500028 |    590 | 160967 |    120 | 119764 |
=====================================================================================================================================
```

#### 常用过滤条件

* tcp.flags.syn == 1 && tcp.flags.ack == 0 客户端握手包

* tcp.flags.reset == 1 && tcp.flags.ack == 0 客户端发过来的rst包

* tcp.analysis.retransmission tcp重传包

* tcp.analysis.lost_segment 数据包丢失

* tcp.analysis.out_of_order 数据包乱序
