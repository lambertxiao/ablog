---
author: "Lambert Xiao"
title: "安装新版gcc"
date: "2022-11-01"
summary: ""
tags: ["c++"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 查找当前gcc的版本

http://ftp.gnu.org/gnu/gcc/

## 下载对应的版本，并解压

```
cd ~/gcc
```

## 使用gcc自带的脚本安装依赖

```
./contrib/download_prerequisites
```

## 生成makefile

```
mkdir build && cd build/
../configure -enable-checking=release -enable-languages=c,c++ -disable-multilib
```

## 编译

```
make -j 8 
```

如果中途出现`g++: error: gengtype-lex.c: No such file or directory`, 需要安装`apt install flex`

## 安装到机器上

```
make install
```
