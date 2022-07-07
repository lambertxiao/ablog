

### 684. 冗余连接

[684. 冗余连接](https://leetcode-cn.com/problems/redundant-connection/)
树可以看成是一个连通且 无环 的 无向 图。

给定往一棵 n 个节点 (节点值 1～n) 的树中添加一条边后的图。添加的边的两个顶点包含在 1 到 n 中间，且这条附加的边不属于树中已存在的边。图的信息记录于长度为 n 的二维数组 edges ，edges[i] = [ai, bi] 表示图中在 ai 和 bi 之间存在一条边。

请找出一条可以删去的边，删除后可使得剩余部分是一个有着 n 个节点的树。如果有多个答案，则返回数组 edges 中最后出现的边。

思路：

假设对于所有的边 [[1,2], [2,3], [3,4], [1,4], [1,5]]

1. 初始时，定义所有节点的代表节点集合parent

parent[i] = i

表示i节点的代表节点是自身i

对于上面的边，五条边，则应该有6个节点，len(parent) = 6

parent = [0, 1, 2, 3, 4, 5]

2. 循环所有的边，判断能否加入这条边到树中

    1. 对于边x-y，如果x的代表节点不等于y的代表节点，说明没有一条路径能让x直接到y，则此时x-y这条边能加入树中，


```go
func findRedundantConnection(edges [][]int) []int {
    // 1.集合树：所有节点以代表节点为父节点构成的多叉树
    // 2.节点的代表节点：可以理解为节点的父节点，从当前节点出发，可以向上找到的第一个节点
    // 3.集合的代表节点：可以理解为根节点，意味着该集合内所有节点向上走，最终都能到达的节点

    parent := make([]int, len(edges) + 1)
    for i := range parent {
        // 索引i表示i节点，值i表示i节点的代表节点
        parent[i] = i
    }

    // 给定一个节点，找到这个节点的代表节点
    var find func(x int) int 
    find = func(x int) int {
        // 初始时x节点的代表节点是自己
        if parent[x] != x {
            // 递归往上找到parent
            parent[x] = find(parent[x])
        }
        return parent[x]
    }

    // 给定一条边 x -> y，判断添加了这条边之后会不会集合树会不会成环
    union := func(x, y int) bool {
        nx, ny := find(x), find(y)

        // 两个节点的代表节点相同，那么原先一定可以从x走到y了，此时再加入x-y这条边，则一定会成环
        if nx == ny {
            return false
        }

        // 更新x的代表节点的代表节点
        // 比如对于边 x-y, z-k, 可以将x-y加入到z-k中，则添加y-k的关系
        parent[nx] = ny
        return true
    }

    for _, edge := range edges {
        if !union(edge[0], edge[1]) {
            return edge
        }
    }
    return nil
}

```