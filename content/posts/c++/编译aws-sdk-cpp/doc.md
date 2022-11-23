---
author: "Lambert Xiao"
title: "编译aws-sdk-cpp"
date: "2022-10-31"
summary: ""
tags: ["c++"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

```
git clone https://github.com/aws/aws-sdk-cpp
cd aws-sdk-cpp
mkdir build && cd build
cmake ../ -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_ONLY="s3"
cmake --build aws-cpp-sdk-core
cmake --build aws-cpp-sdk-s3
cmake --install aws-cpp-sdk-core --prefix ~/workspace/aws
cmake --install aws-cpp-sdk-s3 --prefix ~/workspace/aws
```

`BUILD_ONLY` 选项可以指定编译的模块，不同模块用`;`隔开
