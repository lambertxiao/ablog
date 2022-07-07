---
author: "Lambert Xiao"
title: "算法-两数之和变种"
date: "2022-06-07"
summary: "面试流利说遇到了，做得磕磕绊绊"
tags: ["算法", "动态规划"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

题目：给定一个递增的，含有重复元素的整型数组，求任意两个元素和为target的元素的组合数，

例：[1,1,2,4,4,6,7,7], 求任意两个元素和为8的元素组合数

```go
func count(arr []int, target int) {
    left, right := 0, len(arr) - 1
    ans := 0
    for left < right {
        val := arr[left] + arr[right]
        if val == target {
            // 由于存在重复的元素，需要计算左右各自有多少重复的
            lcnt, rcnt := 1, 1
            left++
            right--

            for left < len(arr) - 1 && arr[left] == arr[left-1] {
                lcnt++
                left++
            }

            for right >= 0 && arr[right] == arr[right+1] {
                rcnt++
                right--
            }
            // 左边的个数*右边的个数得到组合数
            ans += lcnt * rcnt
        } else val > target {
            right--
        } else {
            left++
        }
    }
    return ans
}
```