---
author: "Lambert Xiao"
title: "算法-前缀和"
date: "2022-03-13"
summary: "前缀和也是常见的数组题的解法了吧"
tags: ["算法", "前缀和"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---
### 560. 和为 K 的子数组

[560. 和为 K 的子数组](https://leetcode-cn.com/problems/subarray-sum-equals-k/)
给你一个整数数组 nums 和一个整数 k ，请你统计并返回该数组中和为 k 的连续子数组的个数。

```go
func subarraySum(nums []int, k int) int {
    l := len(nums)
    presum := make([]int, l+1)
    presum[0] = 0
    for i:= 0; i < l; i++ {
        presum[i+1] = presum[i] + nums[i]
    }

    res := 0
    for i := 1; i <= l; i++ {
        for j := 0; j < i; j++ {
            // nums[j]到nums[i-1]的和为k, 
            if presum[i] - presum[j] == k {
                res++
            }
        }
    }

    return res
}
```
