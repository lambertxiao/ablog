---
author: "Lambert Xiao"
title: "动态规划-买卖股票"
date: "2022-03-09"
summary: "啥时候A股的最大收益能用算法算出来也就不用上班了"
tags: ["算法", "动态规划"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/算法-买卖股票.png"
---

## 股票问题

对于股票问题，本质上只有两个维度在变，分别是天数和那一天的状态

### 121. 买卖股票的最佳时机

[121. 买卖股票的最佳时机](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock/)

给定一个数组 prices ，它的第 i 个元素 prices[i] 表示一支给定股票第 i 天的价格。
你只能选择 某一天 买入这只股票，并选择在 未来的某一个不同的日子 卖出该股票。设计一个算法来计算你所能获取的最大利润。
返回你可以从这笔交易中获取的最大利润。如果你不能获取任何利润，返回 0 。

```go
func maxProfit(prices []int) int {
    size := len(prices)
    dp := make([][]int, 2)
    for i := range dp {
        dp[i] = make([]int, 2)
    }

    dp[0][0] = -prices[0]
    dp[0][1] = 0

    for i := 1; i < size; i++ {
        dp[i % 2][0] = max(dp[(i-1)%2][0], -prices[i])
        dp[i % 2][1] = max(dp[(i-1)%2][1], dp[(i-1)%2][0]+prices[i])
    }

    return dp[(size-1)%2][1]
}
```
### 122. 买卖股票的最佳时机 II

[122. 买卖股票的最佳时机 II](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock-ii/)

给定一个数组 prices ，其中 prices[i] 表示股票第 i 天的价格。
在每一天，你可能会决定购买和/或出售股票。你在任何时候 最多 只能持有 一股 股票。你也可以购买它，然后在 同一天 出售。返回 你能获得的 最大 利润 。


```go
func maxProfit(prices []int) int {
    size := len(prices)
    dp := make([][]int, 2)
    for i := range dp {
        dp[i] = make([]int, 2)
    }

    dp[0][0] = -prices[0]
    dp[0][1] = 0

    for i := 1; i < size; i++ {
        dp[i % 2][0] = max(dp[(i-1)%2][0], dp[(i-1)%2][1] - prices[i])
        dp[i % 2][1] = max(dp[(i-1)%2][1], dp[(i-1)%2][0] + prices[i])
    }

    return dp[(size-1)%2][1]
}
```

### 123. 买卖股票的最佳时机 III

[123. 买卖股票的最佳时机 III](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock-iii/)

给定一个数组，它的第 i 个元素是一支给定的股票在第 i 天的价格。
设计一个算法来计算你所能获取的最大利润。你最多可以完成 两笔 交易。
注意：你不能同时参与多笔交易（你必须在再次购买前出售掉之前的股票）。

```go
func maxProfit(prices []int) int {
    size := len(prices)
    dp := make([][]int, 5)
    for i := range dp {
        dp[i] = make([]int, 5)
    }
    // dp[i][j] j有5个状态，0没有操作，1第一次买入，2第一次卖出，3第二次买入，4第二次卖出
    dp[0][1] = -prices[0]
    dp[0][3] = -prices[0]

    for i := 1; i < size; i++ {
        dp[i%5][0] = dp[(i-1)%5][0]
        dp[i%5][1] = max(dp[(i-1)%5][0] - prices[i], dp[(i-1)%5][1])
        dp[i%5][2] = max(dp[(i-1)%5][1] + prices[i], dp[(i-1)%5][2])
        dp[i%5][3] = max(dp[(i-1)%5][2] - prices[i], dp[(i-1)%5][3])
        dp[i%5][4] = max(dp[(i-1)%5][3] + prices[i], dp[(i-1)%5][4])
    }

    return dp[(size-1)%5][4]
}
```

### 188. 买卖股票的最佳时机 IV

[188. 买卖股票的最佳时机 IV](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock-iv/)

给定一个整数数组 prices ，它的第 i 个元素 prices[i] 是一支给定的股票在第 i 天的价格。
设计一个算法来计算你所能获取的最大利润。你最多可以完成 k 笔交易。
注意：你不能同时参与多笔交易（你必须在再次购买前出售掉之前的股票）。

```go
func maxProfit(k int, prices []int) int {
    if len(prices) == 0 {
        return 0
    }
    
    size := len(prices)
    dp := make([][]int, size)
    for i := range dp {
        dp[i] = make([]int, 2 * k + 1)
    }
    // dp[i][j] j有5个状态，0没有操作，1第一次买入，2第一次卖出，...2k-1次买入，2k次卖出
    // basecase偶数位都为0，奇数为-prices[0]
    for j := 1; j < 2 * k + 1; j+=2 {
        dp[0][j] = -prices[0]
    }

    for i := 1; i < size; i++ {
        for j := 0; j < 2 * k - 1; j+=2 {
            dp[i][j+1] = max(dp[i-1][j] - prices[i], dp[i-1][j+1])
            dp[i][j+2] = max(dp[i-1][j+1] + prices[i], dp[i-1][j+2])
        }
    }

    return dp[size-1][2*k]
}
```

### 309. 最佳买卖股票时机含冷冻期

[309. 最佳买卖股票时机含冷冻期](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/)

给定一个整数数组prices，其中第  prices[i] 表示第 i 天的股票价格 。​
设计一个算法计算出最大利润。在满足以下约束条件下，你可以尽可能地完成更多的交易（多次买卖一支股票）:
卖出股票后，你无法在第二天买入股票 (即冷冻期为 1 天)。
注意：你不能同时参与多笔交易（你必须在再次购买前出售掉之前的股票）

```go
func maxProfit(prices []int) int {
    size := len(prices)
    if size == 0 {
        return 0
    }

    dp := make([][]int, size)
    for i := range dp {
        dp[i] = make([]int, 4)
    }
    // 状态有，0买入状态，1之前卖出，2刚卖出，3处于冷冻期
    dp[0][0] = -prices[0]
    for i := 1; i < size; i++ {
        dp[i][0] = max(dp[i-1][0], max(dp[i-1][3], dp[i-1][1]) - prices[i])
        dp[i][1] = max(dp[i-1][1], dp[i-1][3]) // 冷冻期只有一天，到今天就不是冷冻期了
        dp[i][2] = dp[i-1][0] + prices[i]
        dp[i][3] = dp[i-1][2]
    }
    return max(max(dp[size-1][1], dp[size-1][2]), dp[size-1][3])
}
```

### 714. 买卖股票的最佳时机含手续费

[714. 买卖股票的最佳时机含手续费](https://leetcode-cn.com/problems/best-time-to-buy-and-sell-stock-with-transaction-fee/)

给定一个整数数组 prices，其中 prices[i]表示第 i 天的股票价格 ；整数 fee 代表了交易股票的手续费用。
你可以无限次地完成交易，但是你每笔交易都需要付手续费。如果你已经购买了一个股票，在卖出它之前你就不能再继续购买股票了。
返回获得利润的最大值。
注意：这里的一笔交易指买入持有并卖出股票的整个过程，每笔交易你只需要为支付一次手续费。

```go
func maxProfit(prices []int, fee int) int {
    size := len(prices)
    dp := make([][]int, 2)
    for i := range dp {
        dp[i] = make([]int, 2)
    }

    dp[0][0] = -prices[0]
    dp[0][1] = 0

    for i := 1; i < size; i++ {
        dp[i % 2][0] = max(dp[(i-1)%2][0], dp[(i-1)%2][1] - prices[i])
        dp[i % 2][1] = max(dp[(i-1)%2][1], dp[(i-1)%2][0] + prices[i] - fee)
    }

    return dp[(size-1)%2][1]
}
```
