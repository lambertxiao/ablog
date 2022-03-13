---
author: "Lambert Xiao"
title: "算法-滑动窗口"
date: "2022-03-13"
summary: "LR两指针"
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
#   image: "/cover/golang-内存管理.png"
---
### 3. 无重复字符的最长子串

[3. 无重复字符的最长子串](https://leetcode-cn.com/problems/longest-substring-without-repeating-characters/)

给定一个字符串 s ，请你找出其中不含有重复字符的 最长子串 的长度

```go
func lengthOfLongestSubstring(s string) int {
    l, r := 0, 0

    window := make(map[byte]bool)
    ans := 0
    for ; r < len(s); r++ {
        c := s[r]
        for window[c] {
            window[s[l]] = false
            l++
        }
        window[c] = true
        ans = max(ans, r - l + 1)
    }
    return ans
}
```

1. 使用一个hash表window维护当前的子串
2. 如果要加入的字符c已经在window内了，则移动L指针，直到window里不包含字符c
3. 如果要加入的字符c不在window里，则直接加入window
4. 每放入一个字符，则计算一遍当前的最大字串的长度

### 76. 最小覆盖子串

[76. 最小覆盖子串](https://leetcode-cn.com/problems/minimum-window-substring/)
给你一个字符串 s 、一个字符串 t 。返回 s 中涵盖 t 所有字符的最小子串。如果 s 中不存在涵盖 t 所有字符的子串，则返回空字符串 "" 。

注意：

对于 t 中重复字符，我们寻找的子字符串中该字符数量必须不少于 t 中该字符数量。
如果 s 中存在这样的子串，我们保证它是唯一的答案。

```go
func minWindow(s string, t string) string {
    if len(s) < len(t) { return "" }

    needs := make([]int, 128)
    for _, c := range t {
        needs[c]++
    }

    window := make([]int, 128)
    l, r := 0, 0
    n, match := len(t), 0
    minBegin, minLen := 0, 100001

    for r < len(s) {
        c := s[r]
        window[c]++

        if window[c] <= needs[c] {
            match++
        }
        r++

        for match == n {
            if r - l < minLen {
                minLen = r - l
                minBegin = l
            }

            // 当前窗口内的值已经满足需求了，尝试能否从左边缩小窗口
            deleteChar := s[l]
            window[deleteChar]--
            
            if window[deleteChar] < needs[deleteChar] {
                match--
            }

            // 继续缩小
            l++
        }
    }
    if minLen == 100001 {
        return ""
    }
    return s[minBegin:minBegin+minLen]
}
```

### 438. 找到字符串中所有字母异位词

[438. 找到字符串中所有字母异位词](https://leetcode-cn.com/problems/find-all-anagrams-in-a-string/)
给定两个字符串 s 和 p，找到 s 中所有 p 的 异位词 的子串，返回这些子串的起始索引。不考虑答案输出的顺序。

异位词 指由相同字母重排列形成的字符串（包括相同的字符串）。

```go
func findAnagrams(s string, p string) []int {
    res := []int{}
    if len(s) < len(p) {
        return res
    }

    // 需要匹配的字符
    matchChars := make([]int, 26)
    for _, c := range p {
        matchChars[c - 'a']++
    }

    // 定义双指针
    left, right := 0, 0
    // 记录[left, right]范围内的字符统计
    currChars := make([]int, 26)

    for right < len(s) {
        rightChar := s[right] - 'a'
        // 当前范围内rightChar这个字符+1
        currChars[rightChar]++

        // 如果加入字符后，当前范围内的字符已经超过了需要匹配的字符数
        for currChars[rightChar] > matchChars[rightChar] {
            // 移动左边，减少范围内的字符
            currChars[s[left] - 'a']--
            left++
        }

        if right - left + 1 == len(p) {
            res = append(res, left)
        }

        right++
    }

    return res
}
```

[239. 滑动窗口最大值](https://leetcode-cn.com/problems/sliding-window-maximum/)
给你一个整数数组 nums，有一个大小为 k 的滑动窗口从数组的最左侧移动到数组的最右侧。你只可以看到在滑动窗口内的 k 个数字。滑动窗口每次只向右移动一位。

返回 滑动窗口中的最大值 。

```go
func maxSlidingWindow(nums []int, k int) []int {
    q := &dq{data: []int{}, k: k}

    ans := []int{}
    for i := 0; i < len(nums); i++ {
        q.Push(nums[i])
        if i >= k - 1 {
            ans = append(ans, q.Top())
            q.Pop(nums[i-k+1])
        }
    }
    return ans
}

type dq struct {
    data []int
    k int
}

func (q *dq) Push(i int) {
    d := q.data
    for len(d) != 0 && d[len(d)-1] < i {
        d = d[:len(d)-1]
    }
    d = append(d, i)
    q.data = d
} 

func (q *dq) Pop(i int) {
    if i == q.Top() {
        q.data = q.data[1:]
    }
}

func (q *dq) Top() int {
    return q.data[0]
}
```