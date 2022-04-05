---
author: "Lambert Xiao"
title: "算法-子串子序列问题"
date: "2022-03-13"
summary: "子串和子序列是一块难啃的骨头，但大多数时候可以通过动态规划来解决"
tags: ["算法", "动态规划"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
#   image: "/cover/golang-内存管理.png"
---

### 5. 最长回文子串

[5. 最长回文子串](https://leetcode-cn.com/problems/longest-palindromic-substring/)

给你一个字符串 s，找到 s 中最长的回文子串。

```go
func longestPalindrome(s string) string {
    n := len(s)
    dp := make([][]bool, n)
    for i := range dp {
        dp[i] = make([]bool, n)
    }
    dp[0][0] = true

    begin, maxLen := 0, 1
    for j := 1; j < n; j++ {
        for i := j; i >= 0; i-- { {
            if i == j {
                dp[i][j] = true // basecase
            } else if s[i] == s[j] {
                if j - i <= 2 {
                    dp[i][j] = true
                } else {
                    dp[i][j] = dp[i+1][j-1]
                }
                if dp[i][j] {
                    if j - i + 1 > maxLen {
                        maxLen = j - i + 1
                        begin = i
                    }
                }
            } else if s[i] != s[j] {
                dp[i][j] = false
            }
        }
    }
    
    return s[begin:begin+maxLen]
}
```

1. 明确dp的定义，dp[i][j]的定义为s[i..j]是否为回文串
2. 明确i，j的变化方向，确定外层循环是i还是j

    > 举个例子，当求dp[1][5]是否是回文串，需要先知道dp[2][4]是否是回文串，所以i是从大到小遍历，而j是从小到大遍历，所以外层循环是j，内层循环是i，

3. 每计算出一个回文子串，更新begin和length的值

### 53. 最大子数组和

[53. 最大子数组和](https://leetcode-cn.com/problems/maximum-subarray/)
给你一个整数数组 nums ，请你找出一个具有最大和的连续子数组（子数组最少包含一个元素），返回其最大和。

子数组 是数组中的一个连续部分。

```go
func maxSubArray(nums []int) int {
    l := len(nums)
    max := nums[0]

    for i := 1; i < l; i++ {
        if nums[i] + nums[i-1] > nums[i] {
            // 这里利用nums[i]直接记录每次的累加和
            nums[i] = nums[i] + nums[i-1]
        }

        if nums[i] > max {
            max = nums[i]
        } 
    }

    return max
}
```

### 300. 最长递增子序列

[300. 最长递增子序列](https://leetcode-cn.com/problems/longest-increasing-subsequence/)

给你一个整数数组 nums ，找到其中最长严格递增子序列的长度。

子序列 是由数组派生而来的序列，删除（或不删除）数组中的元素而不改变其余元素的顺序。例如，[3,6,2,7] 是数组 [0,3,1,6,2,2,7] 的子序列。


```go
func lengthOfLIS(nums []int) int {
    l := len(nums)
    // dp[i] 表示以 nums[i] 这个数结尾的最长递增子序列的长度。
    dp := make([]int, l)
    for i := 0; i < l; i++ {
        // 每个位置的长度初始值起码有自身一个，因此长度为1
        dp[i] = 1
        // 每到一个i位，需要j从头开始走，计算出在i位时的最长子序列
        for j := 0; j < i; j++ {
            // 当i位置比j位置的值大，长度+1
            if nums[i] > nums[j] {
                dp[i] = max(dp[i], dp[j] + 1)
            } 
        }
    }

    res := 0
    // 最长的子序列并不一定出现在最后一位，所以要全部位置遍历一边
    for _, v := range dp {
        res = max(res, v)
    }

    return res
}
```

### 1143. 最长公共子序列

[1143. 最长公共子序列](https://leetcode-cn.com/problems/longest-common-subsequence/)

给定两个字符串 text1 和 text2，返回这两个字符串的最长 公共子序列 的长度。如果不存在 公共子序列 ，返回 0 。

一个字符串的 子序列 是指这样一个新的字符串：它是由原字符串在不改变字符的相对顺序的情况下删除某些字符（也可以不删除任何字符）后组成的新字符串。

例如，"ace" 是 "abcde" 的子序列，但 "aec" 不是 "abcde" 的子序列。
两个字符串的 公共子序列 是这两个字符串所共同拥有的子序列。

```go
func longestCommonSubsequence(text1 string, text2 string) int {
    // dp[i][j] 表示s1[0..i]和s2[0..j]的最长公共子序列的长度
    m, n := len(text1), len(text2)
    dp := make([][]int, m+1) // 0表示空字符，所以这里要+1
    for i := range dp {
        dp[i] = make([]int, n+1)
    }

    for i := 0; i <= m; i++ { // <=
        // 空字符串与任何字符串的最长公共子序列的长度都为0
        dp[i][0] = 0
    }
    for j := 0; j <= n; j++ {
        dp[0][j] = 0
    }

    for i := 1; i <= m; i++ {
        for j := 1; j <= n; j++ {
            if text1[i-1] == text2[j-1] {
                // 两边新增一个相同的字符，长度在原来的基础上+1
                dp[i][j] = dp[i-1][j-1] + 1
            } else {
                // 两边新增了一个不同的字符，首先长度上不可能增加
                // 新增加的字符可以拿到两遍去匹配原来的字符，取两者较大的那个值
                // 考虑 s1 = abc, s2 = abe，此时分别来了一个字符e和h，得到abce和abeh
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
            }
        }
    }
    return dp[m][n]
}
```

### 718. 最长重复子数组

[718. 最长重复子数组](https://leetcode-cn.com/problems/maximum-length-of-repeated-subarray/)

给两个整数数组 nums1 和 nums2 ，返回 两个数组中 公共的 、长度最长的子数组的长度 。

```go
func findLength(nums1 []int, nums2 []int) int {
    // dp[i][j]表示nums1[0..i]和nums2[0..j]的最长公共子数组的长度
    m, n := len(nums1), len(nums2)
    dp := make([][]int, m + 1)
    for i := range dp {
        dp[i] = make([]int, n + 1)
    }

    for i := 0; i <= m; i++ {
        // 空数组与其他任何数组的公共子数组的长度都为0
        dp[i][0] = 0
    }
    for j := 0; j <= n; j++ {
        dp[0][j] = 0
    }

    ans := 0
    for i := 1; i <= m; i++ {
        for j := 1; j <= n; j++ {
            if nums1[i-1] == nums2[j-1] {
                dp[i][j] = dp[i-1][j-1] + 1
                if dp[i][j] > ans {
                    ans = dp[i][j]
                }
            }
        }
    }
    
    return ans
}
```

### 115. 不同的子序列

[115. 不同的子序列](https://leetcode-cn.com/problems/distinct-subsequences/)

给定一个字符串 s 和一个字符串 t ，计算在 s 的子序列中 t 出现的个数。

字符串的一个 子序列 是指，通过删除一些（也可以不删除）字符且不干扰剩余字符相对位置所组成的新字符串。（例如，"ACE" 是 "ABCDE" 的一个子序列，而 "AEC" 不是）

题目数据保证答案符合 32 位带符号整数范围。

```go
func numDistinct(s string, t string) int {
    n, m := len(s), len(t)
    // dp[i][j]表示t[0:j-1]在s[0:i-1]中出现的个数
    dp := make([][]int, n + 1)
    for i := range dp {
        dp[i] = make([]int, m + 1)
    }

    for i := 0; i < n; i++ {
        dp[i][0] = 1
    }

    for i := 1; i <= n; i++ {
        for j := 1; j <= m; j++ {
            if s[i-1] == t[j-1] {
                dp[i][j] = dp[i-1][j-1] + dp[i-1][j]
            } else {
                dp[i][j] = dp[i-1][j]
            }
        }
    }

    return dp[n][m]
}
```
### 647. 回文子串

[647. 回文子串](https://leetcode-cn.com/problems/palindromic-substrings/)
给你一个字符串 s ，请你统计并返回这个字符串中 回文子串 的数目。

回文字符串 是正着读和倒过来读一样的字符串。

子字符串 是字符串中的由连续字符组成的一个序列。

具有不同开始位置或结束位置的子串，即使是由相同的字符组成，也会被视作不同的子串。

```go
func countSubstrings(s string) int {
    size := len(s)
    dp := make([][]bool, size)
    for i := range dp {
        dp[i] = make([]bool, size)
    }

    cnt := 0
    for j := 0; j < size; j++ {
        for i := 0; i <= j; i++ {
            if i == j { // basecase
                dp[i][j] = true
                cnt++
                continue
            } else if j - i == 1 && s[i] == s[j] { // basecase， 两个字符
                dp[i][j] = true
                cnt++
                continue
            } else if s[i] == s[j] && dp[i+1][j-1] {
                dp[i][j] = true
                cnt++
            }
        }
    }
    return cnt
}
```

### 128. 最长连续序列

[128. 最长连续序列](https://leetcode-cn.com/problems/longest-consecutive-sequence/)
给定一个未排序的整数数组 nums ，找出数字连续的最长序列（不要求序列元素在原数组中连续）的长度。

请你设计并实现时间复杂度为 O(n) 的算法解决此问题。

```go
func longestConsecutive(nums []int) int {
    mem := make(map[int]bool)
    for _, n := range nums {
        mem[n] = true
    }

    maxCnt := 0
    for n := range mem {
        // 计算从k字符出发能拿到的最长串
        cnt := 1

        // 妙啊，这里需要防止一个数被重复计算
        // 如果上一个数也在mem里，那应该从上一个数开始，去计算整个最长串
        if !mem[n-1] {
            for mem[n+1] {
                cnt++
                n++
            }
        }
        
        if cnt > maxCnt {
            maxCnt = cnt
        }
    }

    return maxCnt
}
```