---
author: "Lambert Xiao"
title: "动态规划-打家劫舍"
date: "2022-03-09"
summary: "不会打家劫舍的程序员不是好的小偷"
tags: ["算法", "动态规划"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/算法-打家劫舍.png"
---

## 打家劫舍

用动态规划团灭打家劫舍题目

[198. 打家劫舍](https://leetcode-cn.com/problems/house-robber/)

你是一个专业的小偷，计划偷窃沿街的房屋。每间房内都藏有一定的现金，影响你偷窃的唯一制约因素就是相邻的房屋装有相互连通的防盗系统，如果两间相邻的房屋在同一晚上被小偷闯入，系统会自动报警。
给定一个代表每个房屋存放金额的非负整数数组，计算你 不触动警报装置的情况下 ，一夜之内能够偷窃到的最高金额。

```go
func rob(nums []int) int {
    length := len(nums)
    if length == 0 {
        return 0
    }

    if length == 1 {
        return nums[0]
    }
    
    d := make([]int, length)
    d[0] = nums[0]
    d[1] = max(nums[0], nums[1])

    for i := 2; i < length; i++ {
        d[i] = max(d[i - 1], d[i - 2] + nums[i])
    }
    
    return d[length-1]
}
```

[213. 打家劫舍 II](https://leetcode-cn.com/problems/house-robber-ii/)

你是一个专业的小偷，计划偷窃沿街的房屋，每间房内都藏有一定的现金。这个地方所有的房屋都 围成一圈，这意味着第一个房屋和最后一个房屋是紧挨着的。同时，相邻的房屋装有相互连通的防盗系统，如果两间相邻的房屋在同一晚上被小偷闯入，系统会自动报警 。
给定一个代表每个房屋存放金额的非负整数数组，计算你 在不触动警报装置的情况下 ，今晚能够偷窃到的最高金额。

```go
func rob(nums []int) int {
    l := len(nums)
    if l == 1 {
        return nums[0]
    }

    if l == 2 {
        return max(nums[0], nums[1])
    }

    d1 := make([]int, l-1)
    d2 := make([]int, l)

    // 去掉尾巴
    d1[0] = nums[0]
    d1[1] = max(nums[0], nums[1])
    
    // 去掉头
    d2[1] = nums[1]
    d2[2] = max(nums[1], nums[2])

    for i := 2; i < l - 1; i++ {
        d1[i] = max(d1[i - 1], d1[i - 2] + nums[i])
        d2[i+1] = max(d2[i], d2[i - 1] + nums[i+1])
    }

    return max(d1[l-2], d2[l-1])
}
```

[337. 打家劫舍 III](https://leetcode-cn.com/problems/house-robber-iii/)

小偷又发现了一个新的可行窃的地区。这个地区只有一个入口，我们称之为 root 。
除了 root 之外，每栋房子有且只有一个“父“房子与之相连。一番侦察之后，聪明的小偷意识到“这个地方的所有房屋的排列类似于一棵二叉树”。 如果 两个直接相连的房子在同一天晚上被打劫 ，房屋将自动报警。
给定二叉树的 root 。返回 在不触动警报的情况下 ，小偷能够盗取的最高金额 。

```go
func rob(root *TreeNode) int {
    if root == nil {
        return 0
    }

    val := robNode(root)
    return max(val[0], val[1])
}

// 返回一个节点偷与不偷的两种情况的金额
func robNode(root *TreeNode) []int {
    if root == nil {
        return []int{0, 0}
    }

    left := robNode(root.Left)
    right := robNode(root.Right)

    // 偷当前节点
    val1 := root.Val + left[1] + right[1] 
    // 不偷当前节点 = 左节点里偷与不偷取最大值 + 右节点里偷与不偷取最大值
    val2 := max(left[0], left[1]) + max(right[0], right[1])

    return []int{val1, val2}
}
```
