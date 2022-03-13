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

