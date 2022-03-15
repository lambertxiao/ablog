---
author: "Lambert Xiao"
title: "Epoll思维导图"
date: "2022-03-06"
summary: "一颗红黑树，一个就绪句柄链表，一个进程等待队列，少量的内核cache"
tags: ["epoll"]
categories: ["epoll"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

https://zhuanlan.zhihu.com/p/353692786?utm_medium=social&utm_oi=947783647009439744

## 为啥需要Epoll

设想一个场景：有100万用户同时与进程A保持着TCP连接，而每一时刻只有几十个或几百个TCP连接是活跃的(接收TCP包)，也就是说在每一时刻进程只需要处理这100万连接中的一小部分连接。那么，如何才能高效的处理这种场景呢？

### select和poll是怎么做的：

把进程A添加到这100万个socket的等待队列中，当有一个socket收到数据，进程A会被操作系统唤醒。唤醒之后，进程A并不知道它被哪个socket就绪了，因此它需要去遍历所有的socket列表，找到就绪的socket

### epoll是怎么做的

它在Linux内核中申请了一个简易的文件系统，把原先的一个select或poll调用分成了3部分

```c
int epoll_create(int size);
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
int epoll_wait(int epfd, struct epoll_event *events,int maxevents, int timeout);
```

1. 首先，epoll会向内核注册了一个文件系统，用于存储被监控socket。

2. epoll在被内核初始化时，同时会开辟出epoll自己的内核高速cache区，用于安置每一个我们想监控的socket，这些socket会以红黑树的形式保存在内核cache里，以支持快速的查找、插入、删除。

3. 当调用epoll_create时，就会在这个虚拟的epoll文件系统里创建一个file结点。当然这个file不是普通文件，它只服务于epoll。

4. epoll_create时，内核会创建一个eventpoll对象，等待队列（放进程引用），就绪列表 （存放准备好的事件），rbt红黑树（存放epitem, epitem持有这socket的fd）

5. 接下来调用epoll_ctl时，做了两件事：
    1. 将socket的fd封装为epitem后，加入红黑树中（使用红黑树是综合增，删，查各个操作）
    2. 给内核的中断程序注册一个回调函数，告诉内核，如果这个句柄的中断到了，就把它放到rdlist里

6. 当一个socket里有数据到了，内核把网卡上的数据copy到内核中后就把socket插入到rdlist里，调用epoll_wait时，就是检查rdlist里是否有内容，有内容就返回，无内容就阻塞。如果被阻塞，则进程会加入到等待队列中，等待被唤醒

7. 所以epoll综合来看就是一颗红黑树，一个就绪句柄链表，一个进程等待队列，少量的内核cache

## Epoll的触发模式

- LT水平触发

- ET边缘触发