---
author: "Lambert Xiao"
title: "golang-pprof使用"
date: "2022-06-08"
summary: ""
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## pprof能做什么

pprof能提供正在运行的go程序的各项维度指标，可以帮助我们很好的了解程序的运行状态，如内存的使用，cpu的消耗，是否发现死锁等

### pprof提供的profile

| profile | 解释 |
| - | - |
| cpu | 默认进行 30s 的 CPU Profiling，得到一个分析用的 profile 文件 |
| goroutine | 查看当前所有运行的 goroutines 堆栈跟踪 |
| block | 查看导致阻塞同步的堆栈跟踪 |
| heap | 查看活动对象的内存分配情况 |
| mutex |查看导致互斥锁的竞争持有者的堆栈跟踪 |
| threadcreate | 查看创建新OS线程的堆栈跟踪 |

### 怎么拿到对应的profile文件

当在服务里引入pprof包之后，可能通过http访问的方式拿到profile文件
```
wget - O analysis.pprof http://${ip}:${port}/debug/pprof/${profile}
```

### 怎么分析

以heap.pprof举例

```
// 查看常驻内存的使用情况
go tool pprof -inuse_space heap.pprof

// 查看常驻对象的使用情况
go tool pprof -inuse_objects heap.pprof

// 查看内存临时分配情况
go tool pprof -alloc_space heap.pprof

// 查看对象临时分配情况
go tool pprof -alloc_objects heap.pprof
```

通过top命令可以查看占用最多的地方

```
(pprof) top 20
Showing nodes accounting for 24.34GB, 99.52% of 24.46GB total
Dropped 33 nodes (cum <= 0.12GB)
Showing top 20 nodes out of 34
      flat  flat%   sum%        cum   cum%
   10.36GB 42.37% 42.37%    10.36GB 42.37%  git.ucloudadmin.com/epoch/us3fs/internal.(*Blob).makeAddBh
    7.49GB 30.63% 73.01%     7.49GB 30.63%  git.ucloudadmin.com/epoch/us3fs/internal.(*BufferHead).tryClear
    2.36GB  9.64% 82.64%     2.79GB 11.41%  git.ucloudadmin.com/epoch/us3fs/internal.(*Cacher).getBlob (inline)
    1.82GB  7.46% 90.10%     2.53GB 10.36%  git.ucloudadmin.com/epoch/us3fs/internal.(*US3fs).makeAddInode
    0.65GB  2.65% 92.76%     0.65GB  2.65%  sync.NewCond (inline)
    0.43GB  1.77% 94.53%     0.43GB  1.77%  git.ucloudadmin.com/epoch/us3fs/internal.XMap.init (inline)
    0.33GB  1.37% 95.90%     0.33GB  1.37%  git.ucloudadmin.com/epoch/us3fs/internal.(*Cacher).getBlobSet (inline)
    0.30GB  1.24% 97.14%     0.30GB  1.24%  git.ucloudadmin.com/epoch/us3fs/internal.(*US3fs).makeDentry
    0.28GB  1.14% 98.28%     0.28GB  1.14%  encoding/json.(*decodeState).literalStore
    0.25GB  1.03% 99.31%     3.09GB 12.64%  git.ucloudadmin.com/epoch/us3fs/internal.(*Dir).makeAddChild
    0.05GB  0.21% 99.52%     3.42GB 13.98%  git.ucloudadmin.com/epoch/us3fs/internal.(*Dir).readdirFromOsV2
         0     0% 99.52%     0.28GB  1.14%  encoding/json.(*decodeState).array
         0     0% 99.52%     0.28GB  1.14%  encoding/json.(*decodeState).object
         0     0% 99.52%     0.28GB  1.14%  encoding/json.(*decodeState).unmarshal
         0     0% 99.52%     0.28GB  1.14%  encoding/json.(*decodeState).value
         0     0% 99.52%     0.28GB  1.14%  encoding/json.Unmarshal
         0     0% 99.52%    24.46GB   100%  git.ucloudadmin.com/epoch/go-fuse/fuseutil.(*fileSystemServer).handleOp
         0     0% 99.52%     0.28GB  1.14%  git.ucloudadmin.com/epoch/us3-gosdk.(*UFileRequest).PrefixFileList
         0     0% 99.52%    10.36GB 42.37%  git.ucloudadmin.com/epoch/us3fs/internal.(*Cacher).mapRead
         0     0% 99.52%    20.65GB 84.42%  git.ucloudadmin.com/epoch/us3fs/internal.(*Cacher).read
```

- flat：表示此函数分配、并由该函数持有的内存空间
- flat%：与程序持有总内存的占比
- sum%：
- cum：表示由这个函数或它调用堆栈下面的函数分配的内存总量。
- cum%：与程序持有总内存的占比

![](../heap.png)
