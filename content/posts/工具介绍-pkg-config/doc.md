---
author: "Lambert Xiao"
title: "怎么使用pkg-config"
date: "2023-04-12"
summary: "pkg-config 是一种用于获取已安装软件包编译选项的工具"
tags: ["工具"]
categories: ["工具"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# 简介

pkg-config 是一种用于获取已安装软件包编译选项的工具。它的主要作用是为那些使用 Autoconf 或 Automake 等工具进行软件包管理的开发者提供便利。

pkg-config 支持查询第三方软件包的头文件目录（包含文件夹）、库文件路径和编译选项等信息，以便在编译时链接这些库文件，从而使代码能够顺利地编译并运行。

# 安装

pkg-config 是一个开源软件包，可以在 Linux 或 macOS 系统上通过包管理器直接安装：

```
sudo apt-get install pkg-config

or

sudo yum install pkg-config

or

brew install pkg-config
```

# 使用

pkg-config 主要通过一个`.pc`的文本文件提供编译选项、头文件和库文件等信息。

当安装一个软件包时，通常也会同时安装一个对应的 `.pc` 文件。例如，安装了 `libcurl-dev` 包，就会同时安装一个 `curl.pc` 文件，这个文件中包含了 libcurl 的头文件路径、库文件路径以及选项等信息。

> 需要注意的是，并不是什么软件包都会自带一个.pc文件的，本质上.pc文件只是个文本文件，我们可以自行在机器上为对应的库添加对应的.pc文件

下面以`liburing.pc`文件作为示例

```
prefix=/usr
exec_prefix=${prefix}
libdir=/usr/lib
includedir=/usr/include

Name: liburing
Version: 2.4
Description: io_uring library
URL: https://git.kernel.dk/cgit/liburing/

Libs: -L${libdir} -luring
Cflags: -I${includedir}
```

我们可以使用 pkg-config 工具来查询已安装软件包的信息，其中最常用的命令是 

- `pkg-config --libs` 查询头文件目录
- `pkg-config --cflags` 查询库文件路径和链接选项

## 举些栗子

下面是一些常用的 pkg-config 命令：

查询已安装所有软件包的详细信息：

```
pkg-config --list-all
```

查询 libcurl 库的头文件目录：

```
pkg-config --cflags libcurl

```
查询 libcurl 库的库文件路径和链接选项：

```
pkg-config --libs libcurl
```

## 注意点

在某些情况下，你会发现pkg-config找不到你所指定的库，可能是由于你安装库的路径不是在pkg-config默认的搜索路径上，可通过PKG_CONFIG_PATH环境变量设置搜索路径

常见搜索路径有`/usr/lib/pkgconfig` 和 `/usr/share/pkgconfig` 和 `/usr/local/lib/pkgconfig`

```
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/pkgconfig
```

> 如果同一软件包在不同的 .pc 文件中定义了相同的编译选项，那么最后查询结果会以搜索顺序最靠前的 .pc 文件中定义的选项为准
