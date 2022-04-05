---
author: "Lambert Xiao"
title: "算法-DFS"
date: "2022-03-13"
summary: ""
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 22. 括号生成

[22. 括号生成](https://leetcode-cn.com/problems/generate-parentheses/)
数字 n 代表生成括号的对数，请你设计一个函数，用于能够生成所有可能的并且 有效的 括号组合。

```go
func generateParenthesis(n int) []string {
    ans := []string{}
    var dfs func(lb, rb int, s string)
    dfs = func(lb, rb int, s string) {
        if lb > rb {
            return
        }
        
        if lb == 0 && rb == 0 {
            // 括号用完了，并且是合法的
            if isValid(s) {
                ans = append(ans, s)
            }
            return
        }

        if lb != 0 {
            dfs(lb - 1, rb, s + "(")
        }

        if rb != 0 {
            dfs(lb, rb - 1, s + ")")
        }
    }
    dfs(n, n, "")
    return ans
}

func isValid(s string) bool {
    left := 0
    for _, c := range s {
        if c == '(' {
            left++
        } else {
            if left == 0 {
                return false
            }
            left--
        }
    }
    
    return left == 0
}
```

### 39. 组合总和

[39. 组合总和](https://leetcode-cn.com/problems/combination-sum/)
给你一个 无重复元素 的整数数组 candidates 和一个目标整数 target ，找出 candidates 中可以使数字和为目标数 target 的 所有 不同组合 ，并以列表形式返回。你可以按 任意顺序 返回这些组合。

candidates 中的 同一个 数字可以 无限制重复被选取 。如果至少一个数字的被选数量不同，则两种组合是不同的。 

对于给定的输入，保证和为 target 的不同组合数少于 150 个。

```go
func combinationSum(candidates []int, target int) [][]int {
    res := [][]int{}

    // idx是为了不添加重复的集合
    var backtrace func (sum int, track []int, idx int)
    backtrace = func (sum int, track []int, idx int) {
        if target == sum {
            res = append(res, append([]int{}, track...))
            return
        }

        if sum > target {
            return
        }

        for i := idx; i < len(candidates); i++ {
            c := candidates[i]
            backtrace(sum+c, append(track, c), i)
        }
    }

    backtrace(0, []int{}, 0)
    return res
}
```
### 40. 组合总和 II

[40. 组合总和 II](https://leetcode-cn.com/problems/combination-sum-ii/)
给定一个候选人编号的集合 candidates 和一个目标数 target ，找出 candidates 中所有可以使数字和为 target 的组合。

candidates 中的每个数字在每个组合中只能使用 一次 。

注意：解集不能包含重复的组合。 

```go
func combinationSum2(candidates []int, target int) [][]int {
    sort.Ints(candidates)
    ans := [][]int{}
    
    var backtrace func (sum int, set []int, idx int)
    backtrace = func (sum int, set []int, idx int) {
        if sum == target {
            ans = append(ans, append([]int{}, set...))
            return
        }

        if sum > target {
            return
        }

        for i := idx; i < len(candidates); i++ {
            if i > idx && candidates[i] == candidates[i-1] {
                continue
            }
            val := candidates[i]
            backtrace(sum + val, append(set, val), i+1)
        }
    }

    backtrace(0, []int{}, 0)
    return ans
}
```

### 46. 全排列

[46. 全排列](https://leetcode-cn.com/problems/permutations/)
给定一个不含重复数字的数组 nums ，返回其 所有可能的全排列 。你可以 按任意顺序 返回答案。

```go
func permute(nums []int) [][]int {
    n := len(nums)
    ans := [][]int{}
    used := make([]bool, n)

    var backtrace func(path []int)
    backtrace = func(path []int) {
        if len(path) == n {
            ans = append(ans, append([]int{}, path...))
            return
        }

        for idx, v := range nums {
            if !used[idx] {
                used[idx] = true
                backtrace(append(path, v))
                used[idx] = false
            }
        }
    }
    backtrace([]int{})
    return ans
}
```

### 78. 子集

[78. 子集](https://leetcode-cn.com/problems/subsets/)
给你一个整数数组 nums ，数组中的元素 互不相同 。返回该数组所有可能的子集（幂集）。

解集 不能 包含重复的子集。你可以按 任意顺序 返回解集。

```go
func subsets(nums []int) [][]int {
    size := len(nums)
    ans := [][]int{}

    var backtrace func(startIdx int, path []int)
    backtrace = func(startIdx int, path []int) {
        ans = append(ans, append([]int{}, path...))
        if startIdx >= size {
            return
        }
        for i := startIdx; i < size; i++ {
            backtrace(i+1, append(path, nums[i])) 
        }
    }

    backtrace(0, []int{})
    return ans
}
```

### 79. 单词搜索

[79. 单词搜索](https://leetcode-cn.com/problems/word-search/)
给定一个 m x n 二维字符网格 board 和一个字符串单词 word 。如果 word 存在于网格中，返回 true ；否则，返回 false 。

单词必须按照字母顺序，通过相邻的单元格内的字母构成，其中“相邻”单元格是那些水平相邻或垂直相邻的单元格。同一个单元格内的字母不允许被重复使用。

```go
func exist(board [][]byte, word string) bool {
    workLength := len(word)
    directions := [][]int{
        {-1, 0}, // 往上
        {1, 0}, // 往下
        {0, -1}, // 往左
        {0, 1}, // 往右
    }
    w := len(board)
    h := len(board[0])

    var check func(i, j, k int, visit [][]bool) bool
    check = func(i, j, k int, visit [][]bool) bool {
        if board[i][j] != word[k] {
            return false
        }

        // word已经匹配到最后一位
        if k == workLength - 1 {
            return true
        }

        visit[i][j] = true
        // 朝上下左右继续匹配k+1位
        for _, d := range directions {
            newI := i+d[0]
            newJ := j+d[1]

            if newI >= 0 && newJ >= 0 && newI < w && newJ < h{
                if visit[newI][newJ] {
                    continue
                }

                if check(newI, newJ, k+1, visit) {
                    return true
                }
            }
        }
        visit[i][j] = false
        return false
    }


    for i, row := range board {
        for j := range row {
            visit := geneVisit(w, h)
            if check(i, j, 0, visit) {
                return true
            }
        }
    }

    return false
}

func geneVisit(w, h int) [][]bool {
    visit := make([][]bool, w)
    for i := 0; i < w; i++ {
        visit[i] = make([]bool, h)
    }

    return visit
}
```

### 695. 岛屿的最大面积

[695. 岛屿的最大面积](https://leetcode-cn.com/problems/max-area-of-island/)
给你一个大小为 m x n 的二进制矩阵 grid 。

岛屿 是由一些相邻的 1 (代表土地) 构成的组合，这里的「相邻」要求两个 1 必须在 水平或者竖直的四个方向上 相邻。你可以假设 grid 的四个边缘都被 0（代表水）包围着。

岛屿的面积是岛上值为 1 的单元格的数目。

计算并返回 grid 中最大的岛屿面积。如果没有岛屿，则返回面积为 0 。

```go
func maxAreaOfIsland(grid [][]int) int {
    m, n := len(grid), len(grid[0])

    var dfs func(i, j int) int
    dfs = func(i, j int) int {
        if i < 0 || j < 0 || i >= m || j >= n || grid[i][j] == 0 {
            return 0
        }

        // 沉没岛屿, 避免重复计算
        grid[i][j] = 0
        cnt := 1

        cnt += dfs(i-1, j)
        cnt += dfs(i+1, j)
        cnt += dfs(i, j-1)
        cnt += dfs(i, j+1)
        return cnt
    }

    ans := 0
    for i := 0; i < m; i++ {
        for j := 0; j < n; j++ {
            if grid[i][j] == 1 {
                ans = max(ans, dfs(i, j))
            }
        }
    }
    return ans
}
```

### 130. 被围绕的区域

[130. 被围绕的区域](https://leetcode-cn.com/problems/surrounded-regions/)
给你一个 m x n 的矩阵 board ，由若干字符 'X' 和 'O' ，找到所有被 'X' 围绕的区域，并将这些区域里所有的 'O' 用 'X' 填充。

思路：

1. 需要从上下左右边界开始找（因为从中间找的话可能找到的O其实是跟边界相连着的，此时这个O是不能替换成X的）
2. 替换与边界相连的O为任意字符#
3. 最后遍历整个board，修正整个board

```go
func solve(board [][]byte)  {
    m, n := len(board), len(board[0])

    var dfs func(i, j int)
    dfs = func(i, j int) {
        // 判断i，j是否位于边界
        if i < 0 || i > m - 1 || j < 0 || j > n - 1 || board[i][j] != 'O' {
            return
        }

        // 置为任意字符
        board[i][j] = '#'
        dfs(i+1, j)
        dfs(i-1, j)
        dfs(i, j+1)
        dfs(i, j-1)
    }

    // 从左右两边出发，将与边界上的O字符置为#字符
    for i := 0; i < m; i++ {
        dfs(i, 0)
        dfs(i, n-1)
    }
    // 从上下两边出发，将与边界上的O字符置为#字符
    for j := 0; j < n; j++ {
        dfs(0, j)
        dfs(m-1, j)
    }

    for i := 0; i < m; i++ {
        for j := 0; j < n; j++ {
            // 没有被置为#的O字符，证明没有同边界相连，可以替换
            if board[i][j] == 'O' {
                board[i][j] = 'X'
            } else if board[i][j] == '#' {
                // 对于#，实际上是同边界相连的O，所以需要还原
                board[i][j] = 'O'
            }
        }
    }
}
```
