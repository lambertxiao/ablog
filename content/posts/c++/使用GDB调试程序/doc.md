---
author: "Lambert Xiao"
title: "使用GDB调试程序"
date: "2022-11-07"
summary: ""
tags: ["c++"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

| 命令 | 作用 |
| - | - |
| file | 打开文件 |
| set args | 设置启动参数，如 `set args arg1 arg2` |
| run | 运行 |
| n | 执行下一步 |
| s | 进入方法 |
| c | 跳到下一个断点 |
| b 代码行号 | 设置断点，如 `b foo.h:10` |
| info b | 查看断点 |
| info args | 查看参数 |
| info locals | 查看局部变量 |
| list | 查看当前的10行代码 |
