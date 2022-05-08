---
author: "Lambert Xiao"
title: "算法-拓扑排序"
date: "2022-03-13"
summary: ""
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
#   image: "/cover/golang-内存管理.png"
---

### 207. 课程表

[207. 课程表](https://leetcode-cn.com/problems/course-schedule/)
你这个学期必须选修 numCourses 门课程，记为 0 到 numCourses - 1 。

在选修某些课程之前需要一些先修课程。 先修课程按数组 prerequisites 给出，其中 prerequisites[i] = [ai, bi] ，表示如果要学习课程 ai 则 必须 先学习课程  bi 。

例如，先修课程对 [0, 1] 表示：想要学习课程 0 ，你需要先完成课程 1 。
请你判断是否可能完成所有课程的学习？如果可以，返回 true ；否则，返回 false 。

```go
func canFinish(numCourses int, prerequisites [][]int) bool {
    // 入度
    indeg := make([]int, numCourses)
    // 邻接表
    g := make(map[int][]int)

    for _, q := range prerequisites {
        indeg[q[0]]++
        g[q[1]] = append(g[q[1]], q[0])
    }

    q := make([]int, 0, numCourses)

    // 无入度节点入队
    for i := range indeg {
        if indeg[i] == 0 {
            q = append(q, i)
        } 
    }

    resCount := 0
    for len(q) > 0 {
        head := q[0]
        q = q[1:]
        resCount++

        for _, i := range g[head] {   
            indeg[i]--
            if indeg[i] == 0 {
                q = append(q, i)
            }
        }
    }

    return resCount == numCourses
}
```