---
author: "Lambert Xiao"
title: "动态规划-爬楼梯"
date: "2022-03-09"
summary: "爬个楼梯也事多"
tags: ["算法", "动态规划"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/算法-爬楼梯.png"
---


[70. 爬楼梯](https://leetcode-cn.com/problems/climbing-stairs/)

假设你正在爬楼梯。需要 n 阶你才能到达楼顶。
每次你可以爬 1 或 2 个台阶。你有多少种不同的方法可以爬到楼顶呢？

```go
func climbStairs(n int) int {
    if n == 0 || n == 1 || n == 2 {
        return n
    }

    d := make([]int, n+1)
    d[1] = 1
    d[2] = 2

    i := 3
    for i <= n {
        d[i] = d[i - 1] + d[i - 2]
        i++
    }

    return d[n]
}
```

[746. 使用最小花费爬楼梯](https://leetcode-cn.com/problems/min-cost-climbing-stairs/)

给你一个整数数组 cost ，其中 cost[i] 是从楼梯第 i 个台阶向上爬需要支付的费用。一旦你支付此费用，即可选择向上爬一个或者两个台阶。
你可以选择从下标为 0 或下标为 1 的台阶开始爬楼梯。
请你计算并返回达到楼梯顶部的最低花费。

```go
func minCostClimbingStairs(cost []int) int {
    length := len(cost)
    d := make([]int, length+1)
    d[0] = 0
    d[1] = 0

    for i := 2; i <= length; i++ {
        d[i] = min(cost[i-1] + d[i -1], cost[i - 2] + d[i-2])
    }

    return d[length]
}
```