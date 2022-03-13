---
author: "Lambert Xiao"
title: "算法-位运算"
date: "2022-03-13"
summary: ""
tags: ["算法", "位运算"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 461. 汉明距离

[461. 汉明距离](https://leetcode-cn.com/problems/hamming-distance/)
两个整数之间的 [汉明距离](https://baike.baidu.com/item/%E6%B1%89%E6%98%8E%E8%B7%9D%E7%A6%BB) 指的是这两个数字对应二进制位不同的位置的数目。

给你两个整数 x 和 y，计算并返回它们之间的汉明距离。

```go
func hammingDistance(x int, y int) int {
    s := x ^ y
    // 汉明距离即为s中1的数量
    res := 0

    for s > 0 {
        // 判断最低位是不是1
        res += s & 1
        s >>= 1
    }
     
     return res
}
```
