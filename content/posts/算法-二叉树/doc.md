---
author: "Lambert Xiao"
title: "算法-二叉树"
date: "2022-03-13"
summary: "子串和子序列是一块难啃的骨头，但大多数时候可以通过动态规划来解决"
tags: ["算法", "二叉树"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 617. 合并二叉树

[617. 合并二叉树](https://leetcode-cn.com/problems/merge-two-binary-trees/)
给你两棵二叉树： root1 和 root2 。

想象一下，当你将其中一棵覆盖到另一棵之上时，两棵树上的一些节点将会重叠（而另一些不会）。你需要将这两棵树合并成一棵新二叉树。合并的规则是：如果两个节点重叠，那么将这两个节点的值相加作为合并后节点的新值；否则，不为 null 的节点将直接作为新二叉树的节点。

返回合并后的二叉树。

注意: 合并过程必须从两个树的根节点开始。

```go
func mergeTrees(root1 *TreeNode, root2 *TreeNode) *TreeNode {
    if root1 == nil {
        return root2
    }
    if root2 == nil {
        return root1
    }

    root := &TreeNode{}
    root.Val = root1.Val + root2.Val
    root.Left = mergeTrees(root1.Left, root2.Left)
    root.Right = mergeTrees(root1.Right, root2.Right)

    return root
}
```

### 543. 二叉树的直径

[543. 二叉树的直径](https://leetcode-cn.com/problems/diameter-of-binary-tree/)
给定一棵二叉树，你需要计算它的直径长度。一棵二叉树的直径长度是任意两个结点路径长度中的最大值。这条路径可能穿过也可能不穿过根结点。

```go
func diameterOfBinaryTree(root *TreeNode) int {
    ans := 0

    // fn定义为获取一个节点的深度
    var depth func(root *TreeNode) int
    depth = func(root *TreeNode) int {
        if root == nil { return 0 }

        // 直径即为左深度加右深度
        ld := depth(root.Left)
        rd := depth(root.Right)
        length := ld + rd
        if length > ans {
            ans = length
        }

        // 自己加上左右两边的长度
        return max(ld, rd) + 1
    }

    depth(root)
    return ans
}
```

### 538. 把二叉搜索树转换为累加树

[538. 把二叉搜索树转换为累加树](https://leetcode-cn.com/problems/convert-bst-to-greater-tree/)
给出二叉 搜索 树的根节点，该树的节点值各不相同，请你将其转换为累加树（Greater Sum Tree），使每个节点 node 的新值等于原树中大于或等于 node.val 的值之和。

提醒一下，二叉搜索树满足下列约束条件：

节点的左子树仅包含键 小于 节点键的节点。
节点的右子树仅包含键 大于 节点键的节点。
左右子树也必须是二叉搜索树。

```go
func convertBST(root *TreeNode) *TreeNode {
    preVal := 0
    var traverse func(root *TreeNode)
    traverse = func(root *TreeNode) {
        if root == nil {
            return
        }

        traverse(root.Right)
        root.Val = root.Val + preVal
        preVal = root.Val
        traverse(root.Left)
    }

    traverse(root)
    return root
}
```

### 437. 路径总和 III

[437. 路径总和 III](https://leetcode-cn.com/problems/path-sum-iii/)
给定一个二叉树的根节点 root ，和一个整数 targetSum ，求该二叉树里节点值之和等于 targetSum 的 路径 的数目。

路径 不需要从根节点开始，也不需要在叶子节点结束，但是路径方向必须是向下的（只能从父节点到子节点）。

```go
func pathSum(root *TreeNode, targetSum int) int {
    cnt := 0
    preSum := map[int]int{0: 1}
    // 从root点出发，能找到和为target的path的数量
    var dfs func(root *TreeNode, curr int)
    dfs = func(root *TreeNode, curr int) {
        if root == nil {
            return
        }

        curr += root.Val
        cnt += preSum[curr - targetSum]
        preSum[curr]++
        
        dfs(root.Left, curr)
        dfs(root.Right, curr)
        // 当左边和右边都处理完后，回溯当前的节点产生的和
        preSum[curr]--
    }
    
    dfs(root, 0)
    return cnt
}
```

### 235. 二叉搜索树的最近公共祖先

[235. 二叉搜索树的最近公共祖先](https://leetcode-cn.com/problems/lowest-common-ancestor-of-a-binary-search-tree/)

给定一个二叉搜索树, 找到该树中两个指定节点的最近公共祖先。

百度百科中最近公共祖先的定义为：“对于有根树 T 的两个结点 p、q，最近公共祖先表示为一个结点 x，满足 x 是 p、q 的祖先且 x 的深度尽可能大（一个节点也可以是它自己的祖先）。”


```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val   int
 *     Left  *TreeNode
 *     Right *TreeNode
 * }
 */

func lowestCommonAncestor(root, p, q *TreeNode) *TreeNode {
	if root == nil {
        return nil
    }

    if root == p || root == q {
        return root
    }

    // 在左边找
    if p.Val < root.Val && q.Val < root.Val {
        return lowestCommonAncestor(root.Left, p, q)
    }
    // 在右边找
    if p.Val > root.Val && q.Val > root.Val {
        return lowestCommonAncestor(root.Right, p, q)
    }

    // 一大一小的公共祖先一定是root
    return root
}
```

### 236. 二叉树的最近公共祖先

[236. 二叉树的最近公共祖先](https://leetcode-cn.com/problems/lowest-common-ancestor-of-a-binary-tree/)
给定一个二叉树, 找到该树中两个指定节点的最近公共祖先。

```go
func lowestCommonAncestor(root, p, q *TreeNode) *TreeNode {
    if root == nil {
        return nil
    }

    if root == p || root == q {
        return root
    }

    // 在左边找
    left := lowestCommonAncestor(root.Left, p, q)
    // 在右边找
    right := lowestCommonAncestor(root.Right, p, q)

    // 情况1： p, q不存在
    if left == nil && right == nil {
        return nil
    }

    // 情况2: p，q各自存在与左右子树中
    if left != nil && right != nil {
        return root
    }

    // 情况3: p，qt同在一边
    if left == nil {
        return right
    } else {
        return left
    }
}
```

### 226. 翻转二叉树

[226. 翻转二叉树](https://leetcode-cn.com/problems/invert-binary-tree/)
给你一棵二叉树的根节点 root ，翻转这棵二叉树，并返回其根节点。

```go
func invertTree(root *TreeNode) *TreeNode {
    if root == nil { return nil }
    root.Left, root.Right = root.Right, root.Left
    invertTree(root.Left)
    invertTree(root.Right)
    return root
}
```

### 124. 二叉树中的最大路径和

[124. 二叉树中的最大路径和](https://leetcode-cn.com/problems/binary-tree-maximum-path-sum/)
路径 被定义为一条从树中任意节点出发，沿父节点-子节点连接，达到任意节点的序列。同一个节点在一条路径序列中 至多出现一次 。该路径 至少包含一个 节点，且不一定经过根节点。

路径和 是路径中各节点值的总和。

给你一个二叉树的根节点 root ，返回其 最大路径和 。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func maxPathSum(root *TreeNode) int {
    maxPath := -1001
    var maxGain func(root *TreeNode) int
    maxGain = func(root *TreeNode) int {
        if root == nil {
            return 0
        }
        leftGain := max(maxGain(root.Left), 0)
        rightGain := max(maxGain(root.Right), 0)
        // 当前节点+左边路径+右边路径即为一个path
        maxPath = max(maxPath, root.Val + leftGain + rightGain)

        return root.Val + max(leftGain, rightGain)
    }
    maxGain(root)
    return maxPath
}

func max(x, y int) int {
    if x > y { return x }
    return y
}
```

### 114. 二叉树展开为链表

[114. 二叉树展开为链表](https://leetcode-cn.com/problems/flatten-binary-tree-to-linked-list/)
给你二叉树的根结点 root ，请你将它展开为一个单链表：

展开后的单链表应该同样使用 TreeNode ，其中 right 子指针指向链表中下一个结点，而左子指针始终为 null 。
展开后的单链表应该与二叉树 [先序遍历](https://baike.baidu.com/item/%E5%85%88%E5%BA%8F%E9%81%8D%E5%8E%86/6442839?fr=aladdin) 顺序相同。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func flatten(root *TreeNode)  {
    curr := root
    for curr != nil {
        if curr.Left != nil {
            left := curr.Left
            // 在左子树中寻找最右边的节点，这个节点会是curr右子树的前驱节点
            rLeft := left
            for rLeft.Right != nil {
                rLeft = rLeft.Right
            }
            rLeft.Right = curr.Right
            curr.Right = left
            curr.Left = nil
        }
        curr = curr.Right
    }
}
```

### 105. 从前序与中序遍历序列构造二叉树

[105. 从前序与中序遍历序列构造二叉树](https://leetcode-cn.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/)
给定两个整数数组 preorder 和 inorder ，其中 preorder 是二叉树的先序遍历， inorder 是同一棵树的中序遍历，请构造二叉树并返回其根节点。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func buildTree(preorder []int, inorder []int) *TreeNode {
    if len(inorder) == 0 {
        return nil
    }

    rootVal := preorder[0]
    idx := 0 // 左右子树分节点
    for i, val := range inorder {
        if val == rootVal {
            idx = i
            break
        }
    }

    root := &TreeNode{Val: rootVal}
    root.Left = buildTree(preorder[1:idx+1], inorder[:idx])
    root.Right = buildTree(preorder[idx+1:], inorder[idx+1:])
    return root
}
```

### 106. 从中序与后序遍历序列构造二叉树

[106. 从中序与后序遍历序列构造二叉树](https://leetcode-cn.com/problems/construct-binary-tree-from-inorder-and-postorder-traversal/)
给定两个整数数组 inorder 和 postorder ，其中 inorder 是二叉树的中序遍历， postorder 是同一棵树的后序遍历，请你构造并返回这颗 二叉树 。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func buildTree(inorder []int, postorder []int) *TreeNode {
    if len(inorder) == 0 {
        return nil
    }

    rootVal := postorder[len(postorder)-1]
    idx := 0 // 左右子树分节点
    for i, val := range inorder {
        if val == rootVal {
            idx = i
            break
        }
    }

    root := &TreeNode{Val: rootVal}
    root.Left = buildTree(inorder[:idx], postorder[:idx])
    root.Right = buildTree(inorder[idx+1:], postorder[idx:len(postorder)-1])
    return root
}
```

### 104. 二叉树的最大深度

[104. 二叉树的最大深度](https://leetcode-cn.com/problems/maximum-depth-of-binary-tree/)
给定一个二叉树，找出其最大深度。

二叉树的深度为根节点到最远叶子节点的最长路径上的节点数。

说明: 叶子节点是指没有子节点的节点。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func maxDepth(root *TreeNode) int {
    if root == nil {
        return 0
    }

    return max(maxDepth(root.Left), maxDepth(root.Right)) + 1
}

func max(x, y int) int {
    if x > y { return x }
    return y
}
```

### 102. 二叉树的层序遍历

[102. 二叉树的层序遍历](https://leetcode-cn.com/problems/binary-tree-level-order-traversal/)
给你二叉树的根节点 root ，返回其节点值的 层序遍历 。 （即逐层地，从左到右访问所有节点）。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func levelOrder(root *TreeNode) [][]int {
    ans := [][]int{}
    if root == nil {
        return ans
    }

    q := []*TreeNode{root}
    for len(q) != 0 {
        level := []int{}
        size := len(q)
        for i := 0; i < size; i++ {
            level = append(level, q[i].Val)
            if q[i].Left != nil {
                q = append(q, q[i].Left)
            }
            if q[i].Right != nil {
                q = append(q, q[i].Right)
            }
        }
        ans = append(ans, level)
        q = q[size:]
    }
    return ans
}
```

### 101. 对称二叉树

[101. 对称二叉树](https://leetcode-cn.com/problems/symmetric-tree/)
给你一个二叉树的根节点 root ， 检查它是否轴对称。

```go
func isSymmetric(root *TreeNode) bool {
    return check(root, root)
}

func check(left *TreeNode, right *TreeNode) bool {
    if left == nil && right == nil {
        return true
    }

    if left == nil || right == nil {
        return false
    }

    if left.Val != right.Val {
        return false
    }

    return check(left.Left, right.Right) && check(left.Right, right.Left) 
}
```

### 98. 验证二叉搜索树

[98. 验证二叉搜索树](https://leetcode-cn.com/problems/validate-binary-search-tree/)
给你一个二叉树的根节点 root ，判断其是否是一个有效的二叉搜索树。

有效 二叉搜索树定义如下：

节点的左子树只包含 小于 当前节点的数。
节点的右子树只包含 大于 当前节点的数。
所有左子树和右子树自身必须也是二叉搜索树。

```go
func isValidBST(root *TreeNode) bool {
    return f(root, math.MinInt64, math.MaxInt64)
}

func f(root *TreeNode, min int64, max int64) bool {
    if root == nil {
        return true
    }

    if int64(root.Val) <= min || int64(root.Val) >= max {
        return false
    }

    return f(root.Left, min, int64(root.Val)) && f(root.Right, int64(root.Val), max)
}
```

### 96. 不同的二叉搜索树

[96. 不同的二叉搜索树](https://leetcode-cn.com/problems/unique-binary-search-trees/)
给你一个整数 n ，求恰由 n 个节点组成且节点值从 1 到 n 互不相同的 二叉搜索树 有多少种？返回满足题意的二叉搜索树的种数。

```java
class Solution {
    public int numTrees(int n) {
        // 状态 节点数
        // 选择 选择哪个节点作为根节点
  
        // 状态转移方程
        // dp(n) 使用n个节点，能组成的二叉搜索树种数
        // f(i, n) 使用i节点为根，能组成长度为n的二叉搜索树种数
        // dp(n) = sum(f(i, n)), i属于1到n
        // f(i, n) = dp(i - 1) * dp(n - i)
        // dp(n) = sum(dp(i - 1) * dp(n - i)), i属于1到n

        // baseCase 
        // dp[0] = 0
        // dp[1] = 1
        // dp[2] = 2
        // dp[3] = 5

        int[] dp = new int[n + 1];
        dp[0] = 1;
        dp[1] = 1;

        for (int i = 2; i <= n; i++) {
            for (int j = 1; j <= i; j++) {
                dp[i] += dp[j - 1] * dp[i - j];
            }
        }

        return dp[n];
    }
}
```

### 94. 二叉树的中序遍历

[94. 二叉树的中序遍历](https://leetcode-cn.com/problems/binary-tree-inorder-traversal/)
给定一个二叉树的根节点 root ，返回它的 中序 遍历。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */

// 递归
func inorderTraversal(root *TreeNode) []int {
    ans := []int{}
    var r func(root *TreeNode)
    r = func(root *TreeNode) {
        if root == nil {
            return
        }
        r(root.Left)
        ans = append(ans, root.Val)
        r(root.Right)
    }
    r(root)
    return ans
}

// 迭代
func inorderTraversal2(root *TreeNode) []int {
    if root == nil {
        return []int{}
    }
    // 核心思想要用栈模拟
    stack := []*TreeNode{}
    ans := []int{}
    curr := root // 用来指向当前操作的节点
    for curr != nil || len(stack) != 0 {
        if curr != nil {
            stack = append(stack, curr)
            curr = curr.Left
        } else {
            n := len(stack) - 1
            curr = stack[n]
            stack = stack[:n]
            ans = append(ans, curr.Val)
            curr = curr.Right
        }
    }
    return ans
}
```

### 110. 平衡二叉树

[110. 平衡二叉树](https://leetcode-cn.com/problems/balanced-binary-tree/)
给定一个二叉树，判断它是否是高度平衡的二叉树。

本题中，一棵高度平衡二叉树定义为：

一个二叉树每个节点 的左右两个子树的高度差的绝对值不超过 1 。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func isBalanced(root *TreeNode) bool {
    h := height(root)
    return h != -1
}

func height(root *TreeNode) int {
    if root == nil { return 0 }
    leftH := height(root.Left)
    rightH := height(root.Right)

    if leftH == -1 || rightH == -1 || abs(leftH - rightH) > 1 {
        return -1 // -1代表不平衡，不需要再继续了
    }

    return max(leftH, rightH) + 1
}
```

### 129. 求根节点到叶节点数字之和

[129. 求根节点到叶节点数字之和](https://leetcode-cn.com/problems/sum-root-to-leaf-numbers/)
给你一个二叉树的根节点 root ，树中每个节点都存放有一个 0 到 9 之间的数字。
每条从根节点到叶节点的路径都代表一个数字：

例如，从根节点到叶节点的路径 1 -> 2 -> 3 表示数字 123 。
计算从根节点到叶节点生成的 所有数字之和 。

叶节点 是指没有子节点的节点。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func sumNumbers(root *TreeNode) int {
    if root == nil { return 0 }

    var dfs func(root *TreeNode, sum int) int
    dfs = func(root *TreeNode, sum int) int {
        if root == nil {
            return 0
        }
        rootSum := root.Val + sum * 10
        if root.Left == nil && root.Right == nil {
            return rootSum
        }

        leftSum := dfs(root.Left, rootSum)
        rightSum := dfs(root.Right, rootSum)

        return leftSum + rightSum
    }
    return dfs(root, 0)
}
```

### 109. 有序链表转换二叉搜索树

[109. 有序链表转换二叉搜索树](https://leetcode-cn.com/problems/convert-sorted-list-to-binary-search-tree/)

思路：

1. 找到链表的中点，一分为二
2. 中点为head，并且递归生成左右子树
3. 当 `left == right` 时，证明已经构建完成（可以这么理解，left和right是左闭右开，当left==right时，证明left已经超过边界了）

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func sortedListToBST(head *ListNode) *TreeNode {
    return build(head, nil)
}

func build(left *ListNode, right *ListNode) *TreeNode {
    if left == right {
        return nil
    }
    
    mid := findMid(left, right)
    head := &TreeNode{Val: mid.Val}
    head.Left = build(left, mid)
    head.Right = build(mid.Next, right)
    return head
}

func findMid(left, right *ListNode) *ListNode {
    s, f := left, left
    for f != right && f.Next != right {
        s = s.Next
        f = f.Next.Next
    }
    return s
}
```

### 450. 删除二叉搜索树中的节点

[450. 删除二叉搜索树中的节点](https://leetcode-cn.com/problems/delete-node-in-a-bst/)

给定一个二叉搜索树的根节点 root 和一个值 key，删除二叉搜索树中的 key 对应的节点，并保证二叉搜索树的性质不变。返回二叉搜索树（有可能被更新）的根节点的引用。

一般来说，删除节点可分为两个步骤：

首先找到需要删除的节点；
如果找到了，删除它。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func deleteNode(root *TreeNode, key int) *TreeNode {
    if root == nil {
        return nil
    }

    if root.Val == key {
        // 叶子节点，直接删除
        if root.Left == nil && root.Right == nil {
            // 当前节点被删，返回空
            return nil
        }

        // 左子树为空，右子树上来继位
        if root.Left == nil {
            return root.Right
        }
        // 右子树为空，左子树上来继位
        if root.Right == nil {
            return root.Left
        }
        // 左右都不为空，将左子树的头节点接到右子树里最左节点的左节点上
        leftRoot := root.Left
        leftestNode := root.Right // 右子树里最左边的节点
        for leftestNode.Left != nil {
            leftestNode = leftestNode.Left
        }
        leftestNode.Left = leftRoot
        return root.Right
    }

    if root.Val < key {
        root.Right = deleteNode(root.Right, key)
    } else {
        root.Left = deleteNode(root.Left, key)
    }
    
    return root
}
```

### 297. 二叉树的序列化与反序列化

[297. 二叉树的序列化与反序列化](https://leetcode-cn.com/problems/serialize-and-deserialize-binary-tree/)

序列化是将一个数据结构或者对象转换为连续的比特位的操作，进而可以将转换后的数据存储在一个文件或者内存中，同时也可以通过网络传输到另一个计算机环境，采取相反方式重构得到原数据。

请设计一个算法来实现二叉树的序列化与反序列化。这里不限定你的序列 / 反序列化算法执行逻辑，你只需要保证一个二叉树可以被序列化为一个字符串并且将这个字符串反序列化为原始的树结构。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */

type Codec struct {}

func Constructor() Codec {
    c := Codec{}
    return c
}

// Serializes a tree to a single string.
func (c *Codec) serialize(root *TreeNode) string {
    ans := []string{}
    q := []*TreeNode {root}
    for len(q) != 0 {
        node := q[0]
        q = q[1:]

        if node != nil {
            ans = append(ans, strconv.Itoa(node.Val))
            q = append(q, node.Left)
            q = append(q, node.Right)
        } else {
            ans = append(ans, "X")
        }
    }
    return strings.Join(ans, ",")
}

// Deserializes your encoded data to tree.
func (c *Codec) deserialize(data string) *TreeNode {    
    if data == "X" { return nil } 
    nodes := strings.Split(data, ",")
    v, _ := strconv.Atoi(nodes[0])
    root := &TreeNode{Val: v}
    q := []*TreeNode {root}
    curr := 1

    for curr < len(nodes) {
        node := q[0]
        q = q[1:]

        leftVal := nodes[curr]
        if leftVal != "X" {
            _leftVal, _ := strconv.Atoi(leftVal)
            leftNode := &TreeNode{Val: _leftVal}
            node.Left = leftNode
            q = append(q, leftNode)
        }

        rightVal := nodes[curr+1]
        if rightVal != "X" {
            _rightVal, _ := strconv.Atoi(rightVal)
            rightNode := &TreeNode{Val: _rightVal}
            node.Right = rightNode
            q = append(q, rightNode)
        }
        curr += 2
    }

    return root
}

/**
 * Your Codec object will be instantiated and called as such:
 * ser := Constructor();
 * deser := Constructor();
 * data := ser.serialize(root);
 * ans := deser.deserialize(data);
 */
```

### 700. 二叉搜索树中的搜索

[700. 二叉搜索树中的搜索](https://leetcode-cn.com/problems/search-in-a-binary-search-tree/)

给定二叉搜索树（BST）的根节点 root 和一个整数值 val。

你需要在 BST 中找到节点值等于 val 的节点。 返回以该节点为根的子树。 如果节点不存在，则返回 null 。

```go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
func searchBST(root *TreeNode, val int) *TreeNode {
    if root == nil || root.Val == val {
        return root
    }
    
    if val <= root.Val {
        return searchBST(root.Left, val)
    }
    
    return searchBST(root.Right, val)
}
```

