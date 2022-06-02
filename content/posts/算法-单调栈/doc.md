---
author: "Lambert Xiao"
title: "算法-单调栈"
date: "2022-03-10"
summary: "单调栈总是能解决一些看起来很困难的题"
tags: ["算法", "二分法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
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

### 862. 和至少为 K 的最短子数组
[862. 和至少为 K 的最短子数组](https://leetcode-cn.com/problems/shortest-subarray-with-sum-at-least-k/)

给你一个整数数组 nums 和一个整数 k ，找出 nums 中和至少为 k 的 最短非空子数组 ，并返回该子数组的长度。如果不存在这样的 子数组 ，返回 -1 。

子数组 是数组中 连续 的一部分。

```go
func shortestSubarray(nums []int, k int) int {
    size := len(nums)
    pres := make([]int, size + 1)
    for i, num := range nums {
        pres[i+1] = pres[i] + num
    }

    ans := size + 1
    // 单调递增队列, q里存放索引
    maxq := new(queue)

    for i := 0; i < len(pres); i++ {
        for !maxq.isEmpty() && pres[maxq.last()] > pres[i] {
            maxq.popRight()
        }

        for !maxq.isEmpty() && pres[i] - pres[maxq.first()] >= k {
            ans = min(ans, i - maxq.first())
            maxq.popLeft()
        }

        maxq.pushRight(i)
    }

    if ans < size + 1 {
        return ans
    }

    return -1
}

func min(x, y int) int {
    if x > y { return y }
    return x
} 

type queue []int
func (q *queue) popRight() {
    t := *q
    t = t[:len(t)-1]
    *q = t
}

func (q *queue) pushRight(x int) {
    t := *q
    t = append(t, x)
    *q = t
}

func (q *queue) popLeft() {
    t := *q
    t = t[1:]
    *q = t
}

func (q *queue) last() int {
    t := *q
    return t[len(t)-1]
}

func (q *queue) first() int {
    t := *q
    return t[0]
}

func (q queue) isEmpty() bool {
    return len(q) == 0
}
```

### 316. 去除重复字母
[316. 去除重复字母](https://leetcode-cn.com/problems/remove-duplicate-letters/)

给你一个字符串 s ，请你去除字符串中重复的字母，使得每个字母只出现一次。需保证 返回结果的字典序最小（要求不能打乱其他字符的相对位置）。

```go
func removeDuplicateLetters(s string) string {
    // 统计字符
    cnt := [26]int{}
    for _, c := range s {
        cnt[c-'a']++
    }
    // 统计单调栈中存的字符
    stackCnt := [26]int{}
    // 单调递增栈
    stk := new(stack)

    for _, c := range s {
        cc := byte(c - 'a')
        cnt[cc]-- // 使用掉一个字符就减1
        
        if stackCnt[cc] != 0 {
            continue
        }

        for !stk.isEmpty() && (stk.top() - 'a') > cc {
            last := stk.top() - 'a'
            // 移除一个字符的前提是这个字符是有重复的
            if cnt[last] <= 0 {
                break
            }
            stackCnt[last] = 0
            stk.pop()
        }
        stk.push(byte(c))
        stackCnt[cc] = 1   
    }

    return string(*stk)
}

type stack []byte
func (s *stack) pop() {
    t := *s
    t = t[:len(t)-1]
    *s = t
}
func (s *stack) push(x byte) {
    t := *s
    t = append(t, x)
    *s = t
}
func (s *stack) top() byte {
    t := *s
    return t[len(t)-1]
}
func (s *stack) isEmpty() bool {
    t := *s
    return len(t) == 0
} 
```
