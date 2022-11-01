---
author: "Lambert Xiao"
title: "安装新版gcc"
date: "2022-10-31"
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

## 设置环境变量

```
export CC=/usr/local/bin/gcc
export CXX=/usr/local/bin/g++
```

## 查看默认编译选项

echo "" | gcc -v -x c++ -E -

## 解决GLIBCXX之类的错误

这是因为glibc++的版本太老，先查找

```
whereis libstdc++.so.6

// /usr/lib/x86_64-linux-gnu/libstdc++.so.6

ls -al /usr/lib/x86_64-linux-gnu/libstdc++.so.6

// /usr/lib/x86_64-linux-gnu/libstdc++.so.6 -> libstdc++.so.6.0.24
```

在gcc的build目录下查找新编译出来的libstdc++.so

```
find . -name "*libstdc++*"
```

将找到的libstdc++.so.6.0.30放到/usr/lib/x86_64-linux-gnu/下，并通过软链替换掉原本的指向
