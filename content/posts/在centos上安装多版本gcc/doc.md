---
author: "Lambert Xiao"
title: "在centos上安装多版本gcc"
date: "2023-03-25"
summary: ""
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 前言

有些时候，我们的开发环境需要用到多个版本的gcc, g++，在centos上有方便的工具帮助我们来处理这件事

## 操作步骤

1. 安装centos-release-scl

```
sudo yum install centos-release-scl
```

scl 的含义是 SoftwareCollections，软件集合之意.


2. 安装devtoolset

安装gcc8使用如下命令：

```
yum install devtoolset-8-gcc*
```

安装gcc7使用如下命令：

```
yum install devtoolset-7-gcc*
```

安装的内容会在/opt/rh目录下

3. 激活对应的devtoolset

```
scl enable devtoolset-8 bash
```

它实际上会调用/opt/rh/devtoolset-8/enable 脚本, 完成工具切换

4. 查看版本

```
g++ -v
gcc -v
```
