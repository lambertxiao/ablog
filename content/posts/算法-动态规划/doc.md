---
author: "Lambert Xiao"
title: "算法-动态规划"
date: "2022-03-13"
summary: ""
tags: ["算法", "动态规划"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 55. 跳跃游戏

[55. 跳跃游戏](https://leetcode-cn.com/problems/jump-game/)
给定一个非负整数数组 nums ，你最初位于数组的 第一个下标 。

数组中的每个元素代表你在该位置可以跳跃的最大长度。

判断你是否能够到达最后一个下标。

```go
func canJump(nums []int) bool {
    l := len(nums)
    if l == 0 || l == 1 {
        return true
    }

    // 表示能不能到达第i位下标，true代表可以，false代表不可以
    d := make([]bool, l)
    d[0] = true

    for i := 1; i < l; i++ {
        for j := i - 1; j >= 0; j-- {
            // 能找到一个j就好了
            d[i] = d[j] && (j + nums[j]) >= i 
            if d[i] {
                break
            }
        }

        if !d[i] {
            return false
        }
    }
   
    return d[l - 1]
}
```

### 62. 不同路径

[62. 不同路径](https://leetcode-cn.com/problems/unique-paths/)
一个机器人位于一个 m x n 网格的左上角 （起始点在下图中标记为 “Start” ）。

机器人每次只能向下或者向右移动一步。机器人试图达到网格的右下角（在下图中标记为 “Finish” ）。

问总共有多少条不同的路径？

```go
func uniquePaths(m int, n int) int {
    // dp[i][j] 表示从[0, 0]走到[i, j]总共有多少条路径

    dp := make([][]int, m)
    for i, _ := range dp {
        dp[i] = make([]int, n)
    }

    for i := 0; i < m; i++ {
        for j := 0; j < n; j++ {
            // [i,j] 一定是由[i-1, j]或[i][j-1]过来的
            if i == 0 || j == 0 {
                dp[i][j] = 1
                continue
            }

            dp[i][j] = dp[i-1][j] + dp[i][j-1]
        }
    }

    return dp[m-1][n-1]
}
```

### 64. 最小路径和

[64. 最小路径和](https://leetcode-cn.com/problems/minimum-path-sum/)
给定一个包含非负整数的 m x n 网格 grid ，请找出一条从左上角到右下角的路径，使得路径上的数字总和为最小。

说明：每次只能向下或者向右移动一步。

```go
func minPathSum(grid [][]int) int {
    m, n := len(grid), len(grid[0])
    dp := make([][]int, m)
    for i := range dp {
        dp[i] = make([]int, n)
    }

    dp[0][0] = grid[0][0]
    for i := 1; i < m; i++ {
        dp[i][0] = dp[i-1][0] + grid[i][0]
    }
    for j := 1; j < n; j++ {
        dp[0][j] = dp[0][j-1] + grid[0][j]
    }

    for i := 1; i < m; i++ {
        for j := 1; j < n; j++ {
            dp[i][j] = min(dp[i][j-1], dp[i-1][j]) + grid[i][j]
        }
    }
    return dp[m-1][n-1]
}
```

### 72. 编辑距离

[72. 编辑距离](https://leetcode-cn.com/problems/edit-distance/)
给你两个单词 word1 和 word2， 请返回将 word1 转换成 word2 所使用的最少操作数  。

你可以对一个单词进行如下三种操作：

插入一个字符
删除一个字符
替换一个字符

```go
func minDistance(word1 string, word2 string) int {
    n, m := len(word1), len(word2)
    dp := make([][]int, n+1) 
    // dp[i][j]表示w1[0:i]和w2[0:j]匹配需要的操作次数
    for i := range dp {
        dp[i] = make([]int, m+1)
    }

    for j := 0; j <= m; j++ { // 注意 <=
        dp[0][j] = j
    }
    for i := 0; i <= n; i++ {
        dp[i][0] = i
    }

    for i := 1; i <= n; i++ { // 注意 <=
        for j := 1; j <= m; j++ {
            if word1[i-1] == word2[j-1] {
                dp[i][j] = dp[i-1][j-1]
            } else {
                dp[i][j] = min(min(dp[i-1][j], dp[i-1][j-1]), dp[i][j-1]) + 1
            }
        }
    }
    return dp[n][m]
}
```

### 322. 零钱兑换

[322. 零钱兑换](https://leetcode-cn.com/problems/coin-change/)
给你一个整数数组 coins ，表示不同面额的硬币；以及一个整数 amount ，表示总金额。

计算并返回可以凑成总金额所需的 最少的硬币个数 。如果没有任何一种硬币组合能组成总金额，返回 -1 。

你可以认为每种硬币的数量是无限的。

```go
func coinChange(coins []int, amount int) int {
    if amount == 0 { return 0 }
    // dp[i]表示组成i金额的最少硬币数
    dp := make([]int, amount + 1)
    dp[0] = 0
    for i := 1; i < len(dp); i++ {
        dp[i] = math.MaxInt32
    }

    for i := 1; i <= amount; i++ {
        // 枚举所有的硬币面额
        for _, coin := range coins {
            if i - coin < 0 {
                continue
            }
            // 求组成金额i的最少硬币数 = 组成i-coin + 1
            dp[i] = min(dp[i], dp[i-coin] + 1)
        }
    }
    if dp[amount] == math.MaxInt32 {
        return -1
    }

    return dp[amount]
}
```

### 338. 比特位计数

[338. 比特位计数](https://leetcode-cn.com/problems/counting-bits/)
给你一个整数 n ，对于 0 <= i <= n 中的每个 i ，计算其二进制表示中 1 的个数 ，返回一个长度为 n + 1 的数组 ans 作为答案。

```go
func countBits(n int) []int {
    dp := make([]int, n+1)
    for i := 0; i <= n; i++ {
        if i % 2 == 0 {
            dp[i] = dp[i/2] // 偶数的1的个数，可以想象一个4(0100)和8(1000), 只是左移了一下，末尾补了个0，没有增加1的个数
        } else {
            dp[i] = dp[i-1] + 1 // 奇数的1的个数就是比上个偶数多了个1
        }
    }
    return dp
}
```

### 279. 完全平方数

[279. 完全平方数](https://leetcode-cn.com/problems/perfect-squares/)
给你一个整数 n ，返回 和为 n 的完全平方数的最少数量 。

完全平方数 是一个整数，其值等于另一个整数的平方；换句话说，其值等于一个整数自乘的积。例如，1、4、9 和 16 都是完全平方数，而 3 和 11 不是。

```go
func numSquares(n int) int {
    // dp[i] 表示和为i的完全平方数的最少数量

    dp := make([]int, n+1)

    for i := 1; i <= n; i++ {
        dp[i] = math.MaxInt32
        for j := 1; j * j <= i; j++ {
            dp[i] = min(dp[i-j*j] + 1, dp[i])
        }
    }

    return dp[n]
}
```

### 221. 最大正方形

[221. 最大正方形](https://leetcode-cn.com/problems/maximal-square/)
在一个由 '0' 和 '1' 组成的二维矩阵内，找到只包含 '1' 的最大正方形，并返回其面积。

```go
func maximalSquare(matrix [][]byte) int {
    m, n := len(matrix), len(matrix[0])
    // dp[i + 1][j + 1] 表示 「以第 i 行、第 j 列为右下角的正方形的最大边长」
    dp := make([][]int, m + 1)
    for i := range dp {
        dp[i] = make([]int, n + 1)
    }

    ans := 0
    for i := 0; i < m; i++ {
        for j := 0; j < n; j++ {
            if matrix[i][j] == '1' {
                dp[i+1][j+1] = 1+ min(dp[i][j], min(dp[i+1][j], dp[i][j+1]))
                if dp[i+1][j+1] > ans {
                    ans = dp[i+1][j+1]
                }
            }
        }
    }
    return ans * ans
}
```