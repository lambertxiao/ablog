---
layout: post
title: "Linux下统计代码的工具Cloc"
date: 2019-08-15
tags: [Shell, Bash]
comments: false
---

## Cloc

cloc是linux平台里可以统计代码的工具，并非简单的统计代码的行数，能同时针对各种语言做分类输出

### 安装

```bash
sudo apt install cloc
```

### 使用

```
cloc $filePath
```

返回结果：

```
$ cloc .
    1339 text files.
    1302 unique files.                                          
     160 files ignored.

github.com/AlDanial/cloc v 1.74  T=3.75 s (321.1 files/s, 135799.4 lines/s)
--------------------------------------------------------------------------------
Language                      files          blank        comment           code
--------------------------------------------------------------------------------
Go                              940          39122          40781         354176
C                                37           6806           9795          31924
Markdown                         49           1854              0           6552
C/C++ Header                     37           1330           3531           3864
Assembly                         38            503            884           2402
YAML                             70            145             18           1955
Bourne Shell                     13            139            323            856
JSON                              1              2              0            637
make                              9             73             96            296
Protocol Buffers                  3             38             27            165
SQL                               1              1              0            155
Python                            1             14             13             99
Bourne Again Shell                1              8              3             52
TOML                              2              5             45             11
Dockerfile                        1              1              0              8
--------------------------------------------------------------------------------
SUM:                           1203          50041          55516         403152
--------------------------------------------------------------------------------
```