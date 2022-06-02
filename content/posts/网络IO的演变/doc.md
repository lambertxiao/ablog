---
author: "Lambert Xiao"
title: "网络IO的演变"
date: "2022-03-15"
summary: "一颗红黑树，一个就绪句柄链表，一个进程等待队列，少量的内核cache"
tags: ["epoll"]
categories: ["epoll"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover: 
  image: "/cover/epoll示意图.png"
---

https://zhuanlan.zhihu.com/p/353692786?utm_medium=social&utm_oi=947783647009439744

## 网络IO的变化

### BIO

```go
ss := new(socket)
bind(ss, port)
listen(ss)

for {
    s := accept(ss) // 会阻塞住
}
```

优点：

1. 每个连接一个线程去处理，可以同时接收很多连接

缺点：

1. BIO中有两处阻塞，第一个是accept等待客户端连接阻塞，第二个是客户端连接后读取客户端数据recv函数阻塞，因此需要在建立连接后开启一个新线程处理
2. 由于每个连接需要一个线程处理，当连接过多时，线程的内存开销比较大，同时CPU的调度消耗也比较大

### NIO

```go
ss := new(socket)
bind(ss, port)
listen(ss)

for {
    fd := accept(ss) // 该行不会阻塞住，如果fd不为-1，则表示有新的连接
    fd.nonblocking()
    
    for {
        recv(fd) // 此行也不会阻塞，没有数据可读时，会立即返回
    }
}
```

优点：

1. server端accpet客户端连接和读取客户端数据不阻塞，解决了阻塞问题，避免多线程处理多连接的问题

缺点：

1. 假设现在连接的客户端有10w个，此时可能有请求数据的就占极小部分，但这10w个连接每次都需要发起recv请求(一次系统调用)区检查是否有数据到来，这大量浪费了时间和资源

### 第一版IO多路复用(select/poll)

```go
ss := new(socket)
bind(ss, port)
listen(ss)

ss.nonblocking()

for {
    // 内存中记录全部的fd

    select(fds) // poll(fds) 
}
```

优点：

1. 解决了用户需要频繁进行recv系统调用的问题，用户态1次系统调用，交由内核遍历

缺点：

1. 每次需要将所有的fds集合传递给内核，由内核遍历，然后将就绪的readyFds返回，内核态无存储能力
2. 内核实际上也仍需要每次遍历全量的fd

### 第二版IO多路复用(epoll)

```
epoll_create()
epoll_ctl()
epoll_wait()
```

优点：

1. 调用epoll_create时在内核中开辟了一段空间，分别是存放fd的红黑树，就绪列表，等待列表
2. epoll_ctl用来增删改红黑树中的fd
3. epoll_wait阻塞在内核态，就绪队列不为空时，返回用户态

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