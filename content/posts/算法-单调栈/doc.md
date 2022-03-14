---
author: "Lambert Xiao"
title: "算法-单调栈"
date: "2022-03-10"
summary: "最难不过二分，边界问题最蛋疼"
tags: ["算法", "二分法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/算法-二分法.png"
---

### 739. 每日温度

[739. 每日温度](https://leetcode-cn.com/problems/daily-temperatures/)

给定一个整数数组 temperatures ，表示每天的温度，返回一个数组 answer ，其中 answer[i] 是指在第 i 天之后，才会有更高的温度。如果气温在这之后都不会升高，请在该位置用 0 来代替。

```ts
function dailyTemperatures(temperatures: number[]): number[] {
    let res: number[] = []
    let stack: number[] = []

    for (let i = temperatures.length - 1; i >= 0; i--) {
        let len = stack.length
        // 当栈不为空，将此时栈里比当前元素小的干掉
        while (len != 0 && temperatures[stack[len-1]] <= temperatures[i]) {
            stack.pop()
        }

        // 出循环后栈顶即为比当前元素大的元素
        res[i] = len != 0 ? stack[len-1] - i : 0
        stack.push(i)
    }

    return res
}
```

### 1438. 绝对差不超过限制的最长连续子数组

[1438. 绝对差不超过限制的最长连续子数组](https://leetcode-cn.com/problems/longest-continuous-subarray-with-absolute-diff-less-than-or-equal-to-limit/)
给你一个整数数组 nums ，和一个表示限制的整数 limit，请你返回最长连续子数组的长度，该子数组中的任意两个元素之间的绝对差必须小于或者等于 limit 。

如果不存在满足条件的子数组，则返回 0 。

滑动窗口 + 单调递减栈 + 单调递增栈

```go
func longestSubarray(nums []int, limit int) int {
    // 单调递减栈和单调递增栈
    minq, maxq := []int{}, []int{}
    l, r, ans := 0, 0, 0

    for r < len(nums) {
        num := nums[r]
        for len(minq) != 0 && minq[len(minq)-1] < num {
            minq = minq[:len(minq)-1]
        }
        minq = append(minq, num)

        for len(maxq) != 0 && maxq[len(maxq)-1] > num {
            maxq = maxq[:len(maxq)-1]
        }
        maxq = append(maxq, num)

        //  此时maxq里可以拿到最小值，minq里可以拿到最大值
        for len(maxq) > 0 && len(minq) > 0 && minq[0] - maxq[0] > limit {
            if nums[l] == maxq[0] {
                maxq = maxq[1:]
            }
            if nums[l] == minq[0] {
                minq = minq[1:]
            }
            // 在不满足绝对差小于limit的情况下，需要移动窗口左边界
            l++
        }
        ans = max(ans, r - l + 1)
        r++
    }

    return ans
}

func max(x, y int) int {
    if x > y { return x }
    return y
}

```
