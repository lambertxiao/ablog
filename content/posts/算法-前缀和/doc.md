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

### 523. 连续的子数组和

[523. 连续的子数组和](https://leetcode-cn.com/problems/continuous-subarray-sum/)

给你一个整数数组 nums 和一个整数 k ，编写一个函数来判断该数组是否含有同时满足下述条件的连续子数组：

子数组大小 至少为 2 ，且
子数组元素总和为 k 的倍数。
如果存在，返回 true ；否则，返回 false 。

如果存在一个整数 n ，令整数 x 符合 x = n * k ，则称 x 是 k 的一个倍数。0 始终视为 k 的一个倍数。

思路：

1. 利用hash表记录余数和下标的关系
2. 当余数没有出现时，加入hash表中
3. 当余数已经出现过，则判断是否长度大于1
4. 两种情况符合要求：前缀和直接为k的倍数，或者前缀和之差为k的倍数。加一个边界条件0: -1可以省的判断前一种情况
5. i - idx 为什么不是 >= 1, 因为pres的val的下标是从-1开始的


```go
func checkSubarraySum(nums []int, k int) bool {
    if len(nums) < 2 {
        return false
    }

    pres := map[int]int{0: -1}
    sum := 0
    for i, num := range nums {
        sum = (sum + num) % k
        if idx, ok := pres[sum]; ok {
            if i - idx > 1 {
                return true
            }
        } else {
            pres[sum] = i
        }
    }

    return false
}
```

### 528. 按权重随机选择

[528. 按权重随机选择](https://leetcode-cn.com/problems/random-pick-with-weight/)
给你一个 下标从 0 开始 的正整数数组 w ，其中 w[i] 代表第 i 个下标的权重。

请你实现一个函数 pickIndex ，它可以 随机地 从范围 [0, w.length - 1] 内（含 0 和 w.length - 1）选出并返回一个下标。选取下标 i 的 概率 为 w[i] / sum(w) 。

例如，对于 w = [1, 3]，挑选下标 0 的概率为 1 / (1 + 3) = 0.25 （即，25%），而选取下标 1 的概率为 3 / (1 + 3) = 0.75（即，75%）。


思路：

假设对于数组w, w = [2, 5, 1], 则选中下标0的概率为 2 / 8, 选择下标1的概率为 5 / 8，选中下标2的概率为 1 / 8，将数组分为3段看，[1, 2], [3, 7], [7, 8]，那么则在1-8之间随机一个数，并看这个数落在哪个段内

```go
type Solution struct {
    pres []int
}

func Constructor(w []int) Solution {
    // 将w转化为前缀和
    for i := 1; i < len(w); i++ {
        w[i] += w[i-1]
    }

    return Solution{w}
}


func (s *Solution) PickIndex() int {
    weight := s.pres[len(s.pres)-1]
    x := rand.Intn(weight) + 1
    return sort.SearchInts(s.pres, x)
}


/**
 * Your Solution object will be instantiated and called as such:
 * obj := Constructor(w);
 * param_1 := obj.PickIndex();
 */
 ```