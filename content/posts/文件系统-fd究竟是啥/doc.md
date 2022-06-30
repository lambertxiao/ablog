---
author: "Lambert Xiao"
title: "文件系统-fd究竟是啥"
date: "2022-06-30"
summary: "一句话终结"
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

一句话终结

fd是数组的索引，数组是进程结构体`task_struct`里的数组`*files`，`*files`记录着进程打开的文件, fd作为索引指向某个具体的文件`files_struct`

```c
struct task_struct {
    // ...
    /* Open file information: */
    struct files_struct     *files;
    // ...
}

struct files_struct {
    // 读相关字段
    atomic_t count;
    bool resize_in_progress;
    wait_queue_head_t resize_wait;

    // 打开的文件管理结构
    struct fdtable __rcu *fdt;
    struct fdtable fdtab;

    // 写相关字段
    unsigned int next_fd;
    unsigned long close_on_exec_init[1];
    unsigned long open_fds_init[1];
    unsigned long full_fds_bits_init[1];
    struct file * fd_array[NR_OPEN_DEFAULT];
};
```
