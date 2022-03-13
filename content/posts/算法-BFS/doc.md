---
author: "Lambert Xiao"
title: "算法-BFS"
date: "2022-03-13"
summary: ""
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

[200. 岛屿数量](https://leetcode-cn.com/problems/number-of-islands/)
给你一个由 '1'（陆地）和 '0'（水）组成的的二维网格，请你计算网格中岛屿的数量。

岛屿总是被水包围，并且每座岛屿只能由水平方向和/或竖直方向上相邻的陆地连接形成。

此外，你可以假设该网格的四条边均被水包围。

```go
func numIslands(grid [][]byte) int {
    m, n := len(grid), len(grid[0])
    bfs := func(i, j int) {
        // 从[i, j]位置开始扩散
        q := [][]int{{i, j}}
        for len(q) != 0 {
            e := q[0]
            q = q[1:]
            x, y := e[0], e[1]

            if x >= 0 && x < m && y >= 0 && y < n && grid[x][y] == '1' {
                grid[x][y] = '0'
                q = append(q, []int{x+1, y})
                q = append(q, []int{x-1, y})
                q = append(q, []int{x, y+1})
                q = append(q, []int{x, y-1})
            }
        }
    }

    cnt := 0
    for i := 0; i < m; i++ {
        for j := 0; j < n; j++ {
            if grid[i][j] == '0' {
                continue
            }
            bfs(i, j)
            // 为什么找到了一块陆地就可以增加一个岛屿数呢，
            // 是因为在bfs方法中会将跟这块陆地相连的其他陆地染色，不会再次重复计算
            cnt++
        }
    }
    return cnt
}
```