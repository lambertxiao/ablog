---
author: "Lambert Xiao"
title: "算法-链表"
date: "2022-03-13"
summary: ""
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 2. 两数相加

[2. 两数相加](https://leetcode-cn.com/problems/add-two-numbers/)

给你两个 非空 的链表，表示两个非负的整数。它们每位数字都是按照 逆序 的方式存储的，并且每个节点只能存储 一位 数字。

请你将两个数相加，并以相同形式返回一个表示和的链表。
你可以假设除了数字 0 之外，这两个数都不会以 0 开头。

### 206. 反转链表

[206. 反转链表](https://leetcode-cn.com/problems/reverse-linked-list/)
给你单链表的头节点 head ，请你反转链表，并返回反转后的链表。


```go
func reverseList(head *ListNode) *ListNode {
    // 双指针，pre和curr一前一后
    var pre *ListNode
    curr := head

    for curr != nil {
        tmp := curr.Next
        curr.Next = pre
        pre = curr
        curr = tmp
    }

    return pre
}

func reverseList(head *ListNode) *ListNode {
    if head == nil || head.Next == nil {
        return head
    }

    nhead := reverseList(head.Next)
    head.Next.Next = head // 先指向回自己建立联系
    head.Next = nil // 再把多余的联系断掉

    return nhead
}
```


### 19. 删除链表的倒数第 N 个结点

[19. 删除链表的倒数第 N 个结点](https://leetcode-cn.com/problems/remove-nth-node-from-end-of-list/)

给你一个链表，删除链表的倒数第 n 个结点，并且返回链表的头结点。

```go
func removeNthFromEnd(head *ListNode, n int) *ListNode {
    // 快慢指针
    dummy := &ListNode{}
    dummy.Next = head
    s, f := dummy, dummy

    // faster向前走n+1步，一会可以让slow停在想要删除的节点的前继节点上
    for n >= 0 && f != nil {
        f = f.Next
        n--
    }

    for f != nil {
        f = f.Next
        s = s.Next
    }

    s.Next = s.Next.Next
    return dummy.Next
}
```

### 23. 合并K个升序链表

[23. 合并K个升序链表](https://leetcode-cn.com/problems/merge-k-sorted-lists/)

给你一个链表数组，每个链表都已经按升序排列。

请你将所有链表合并到一个升序链表中，返回合并后的链表。

```go
func mergeKLists(lists []*ListNode) *ListNode {
    h := hp{}
    for _, node := range lists {
        if node != nil {
            heap.Push(&h, node)
        }
    }

    dummy := &ListNode{}
    curr := dummy
    for len(h) != 0 {
        node := heap.Pop(&h).(*ListNode)
        curr.Next = node
        curr = curr.Next
        
        if node.Next != nil {
            heap.Push(&h, node.Next)
        }
    }
    return dummy.Next
}

type hp []*ListNode

func (h hp) Swap(i, j int) { h[i], h[j] = h[j], h[i] }
func (h hp) Less(i, j int) bool { return h[i].Val < h[j].Val }
func (h hp) Len() int { return len(h) }
func (h *hp) Push(x interface{}) { *h = append(*h, x.(*ListNode))}
func (h *hp) Pop() interface{} {
    old := *h
    n := len(old)
    e := old[n-1]
    *h = old[:n-1]
    return e
}
```

### 21. 合并两个有序链表

[21. 合并两个有序链表](https://leetcode-cn.com/problems/merge-two-sorted-lists/)

将两个升序链表合并为一个新的 升序 链表并返回。新链表是通过拼接给定的两个链表的所有节点组成的。 

```go
func mergeTwoLists(list1 *ListNode, list2 *ListNode) *ListNode {
    if list1 == nil {
        return list2
    }
    if list2 == nil {
        return list1
    }
    if list1.Val < list2.Val {
        list1.Next = mergeTwoLists(list1.Next, list2)
        return list1
    }

    list2.Next = mergeTwoLists(list2.Next, list1)
    return list2
}
```

### 24. 两两交换链表中的节点

[24. 两两交换链表中的节点](https://leetcode-cn.com/problems/swap-nodes-in-pairs/)

给你一个链表，两两交换其中相邻的节点，并返回交换后链表的头节点。你必须在不修改节点内部的值的情况下完成本题（即，只能进行节点交换）。

```go
func swapPairs(head *ListNode) *ListNode {
    // 递归法：明确swapPairs的含义就是将给定的链表两两反转
    if head == nil || head.Next == nil {
        return head
    }

    // 将当前节点和后继节点反转
    next := head.Next
    // 除了第一个第二个节点外的节点继续去做递归反转，并接到head后面
    head.Next = swapPairs(next.Next)
    // 反转head和next
    next.Next = head
    return next
}
```
### 25. K 个一组翻转链表

[25. K 个一组翻转链表](https://leetcode-cn.com/problems/reverse-nodes-in-k-group/)

给你一个链表，每 k 个节点一组进行翻转，请你返回翻转后的链表。

k 是一个正整数，它的值小于或等于链表的长度。

如果节点总数不是 k 的整数倍，那么请将最后剩余的节点保持原有顺序。

进阶：

你可以设计一个只使用常数额外空间的算法来解决此问题吗？
你不能只是单纯的改变节点内部的值，而是需要实际进行节点交换。

```go
func reverseKGroup(head *ListNode, k int) *ListNode {
    start, end := head, head
    for i := 0; i < k; i++ {
        if end == nil {
            return head // 不足k个
        }
        end = end.Next
    }

    newHead := reverse(start, end)
    start.Next = reverseKGroup(end, k)

    return newHead
}

func reverse(start *ListNode, end *ListNode) *ListNode {
    var pre *ListNode
    curr := start
    for curr != end {
        t := curr.Next
        curr.Next = pre
        pre = curr
        curr = t
    }
    return pre
}
```

### 234. 回文链表

[234. 回文链表](https://leetcode-cn.com/problems/palindrome-linked-list/)
给你一个单链表的头节点 head ，请你判断该链表是否为回文链表。如果是，返回 true ；否则，返回 false 。

```go
func isPalindrome(head *ListNode) bool {
    slow, faster := head, head

    for faster != nil && faster.Next != nil {
        slow = slow.Next
        faster = faster.Next.Next
    }

    left := head 
    right := reverse(slow)

    for left != nil && right != nil {
        if left.Val != right.Val {
            return false
        }
        left = left.Next
        right = right.Next
    }
    return true
}

func reverse(head *ListNode) *ListNode {
    var pre *ListNode
    
    for head != nil {
        next := head.Next
        head.Next = pre
        pre = head
        head = next
    }

    return pre
}
```

### 160. 相交链表

[160. 相交链表](https://leetcode-cn.com/problems/intersection-of-two-linked-lists/)
给你两个单链表的头节点 headA 和 headB ，请你找出并返回两个单链表相交的起始节点。如果两个链表不存在相交节点，返回 null 。

```go
func getIntersectionNode(headA, headB *ListNode) *ListNode {
    if headA == nil || headB == nil { return nil }
    pa, pb := headA, headB

    for pa != pb {
        if pa == nil {
            pa = headB
        } else {
            pa = pa.Next
        }

        if pb == nil {
            pb = headA
        } else {
            pb = pb.Next
        }
    }
    return pa
}
```

### 141. 环形链表

[141. 环形链表](https://leetcode-cn.com/problems/linked-list-cycle/)
给你一个链表的头节点 head ，判断链表中是否有环。

如果链表中有某个节点，可以通过连续跟踪 next 指针再次到达，则链表中存在环。 为了表示给定链表中的环，评测系统内部使用整数 pos 来表示链表尾连接到链表中的位置（索引从 0 开始）。注意：pos 不作为参数进行传递 。仅仅是为了标识链表的实际情况。

如果链表中存在环 ，则返回 true 。 否则，返回 false 。

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func hasCycle(head *ListNode) bool {
    s, f := head, head

    for f != nil {
        if f.Next == nil {
            return false
        }
        f = f.Next.Next
        s = s.Next
        
        if s == f {
            return true
        }
    }
    return false
}
```

### 142. 环形链表 II

[142. 环形链表 II](https://leetcode-cn.com/problems/linked-list-cycle-ii/)
给定一个链表的头节点  head ，返回链表开始入环的第一个节点。 如果链表无环，则返回 null。

如果链表中有某个节点，可以通过连续跟踪 next 指针再次到达，则链表中存在环。 为了表示给定链表中的环，评测系统内部使用整数 pos 来表示链表尾连接到链表中的位置（索引从 0 开始）。如果 pos 是 -1，则在该链表中没有环。注意：pos 不作为参数进行传递，仅仅是为了标识链表的实际情况。

不允许修改 链表。

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func detectCycle(head *ListNode) *ListNode {
    // 设链表共有a+b个节点
    // fast = 2 * slow, fast = slow + nb = > slow = nb
    // 到达环的时候走过的距离为 = a + nb, 所以就是求a，就是在当前s的位置再走a步

    f, s := head, head

    for f != nil {
        if f.Next == nil {
            return nil
        }

        f = f.Next.Next
        s = s.Next

        if f == s {
            break
        }
    }
    if f == nil {
        return nil
    }

    // f走过的距离为2倍的s，并且相遇时f走过了s + nb的距离
    // 让head，slow指针各走a步，去汇合
    for head != nil {
        if head == s {
            return head
        }

        head = head.Next 
        s = s.Next
    }
    return nil
}
```

### 148. 排序链表

[148. 排序链表](https://leetcode-cn.com/problems/sort-list/)
给你链表的头结点 head ，请将其按 升序 排列并返回 排序后的链表 。

```go
func sortList(head *ListNode) *ListNode {
    return sort(head, nil)
}

func sort(head *ListNode, tail *ListNode) *ListNode {
    if head == nil {
        return nil
    }
    if head.Next == tail {
        head.Next = nil
        return head
    }

    mid := findMid(head, tail)
    return merge(sort(head, mid), sort(mid, tail))
}

// 将排好序的链表合并
func merge(l1 *ListNode, l2 *ListNode) *ListNode {
    dummy := &ListNode{}
    curr := dummy

    for l1 != nil || l2 != nil {
        if l1 == nil {
            curr.Next = l2
            l2 = l2.Next
        } else if l2 == nil {
            curr.Next = l1
            l1 = l1.Next
        } else if l1.Val < l2.Val {
            curr.Next = l1
            l1 = l1.Next
        } else {
            curr.Next = l2
            l2 = l2.Next
        }
        curr = curr.Next
    }
    return dummy.Next
}

// 找链表的中点
func findMid(head *ListNode, tail *ListNode) *ListNode {
    s, f := head, head
    for f != tail && f.Next != tail {
        f = f.Next.Next
        s = s.Next
    }

    return s
}
```

### 剑指 Offer 22. 链表中倒数第k个节点

[剑指 Offer 22. 链表中倒数第k个节点](https://leetcode-cn.com/problems/lian-biao-zhong-dao-shu-di-kge-jie-dian-lcof/)
输入一个链表，输出该链表中倒数第k个节点。为了符合大多数人的习惯，本题从1开始计数，即链表的尾节点是倒数第1个节点。

例如，一个链表有 6 个节点，从头节点开始，它们的值依次是 1、2、3、4、5、6。这个链表的倒数第 3 个节点是值为 4 的节点。

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func getKthFromEnd(head *ListNode, k int) *ListNode {
    if head == nil {
        return nil
    }
    
    p, q := head, head
    i := 0

    for i < k {
        if q == nil {
            break
        }
        q = q.Next
        i++
    }

    if i < k {
        return nil
    }

    for q != nil {
        p = p.Next
        q = q.Next
    }

    return p
}
```

### 重排链表

[143. 重排链表](https://leetcode-cn.com/problems/reorder-list/)
给定一个单链表 L 的头节点 head ，单链表 L 表示为：

L0 → L1 → … → Ln - 1 → Ln
请将其重新排列后变为：

L0 → Ln → L1 → Ln - 1 → L2 → Ln - 2 → …
不能只是单纯的改变节点内部的值，而是需要实际的进行节点交换。

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func reorderList(head *ListNode) {
    if head == nil {
        return
    }
    mid := middleNode(head)
    nhead := reverseList(mid.Next)
    mid.Next = nil // 断掉
    mergeList(head, nhead)
    return 
}

func mergeList(l1, l2 *ListNode) {
    for l1 != nil && l2 != nil {
        t1 := l1.Next
        t2 := l2.Next

        l1.Next = l2
        l1 = t1

        l2.Next = t1
        l2 = t2
    }
}

func middleNode(head *ListNode) *ListNode {
    f, s := head, head
    for f != nil && f.Next != nil {
        f = f.Next.Next
        s = s.Next
    }
    return s
}

func reverseList(head *ListNode) *ListNode {
    if head == nil {
        return nil
    }
    var pre *ListNode
    curr := head

    for curr != nil {
        t := curr.Next
        curr.Next = pre
        pre = curr
        curr = t
    }
    return pre
}
```
### 138. 复制带随机指针的链表

[138. 复制带随机指针的链表](https://leetcode-cn.com/problems/copy-list-with-random-pointer/)
给你一个长度为 n 的链表，每个节点包含一个额外增加的随机指针 random ，该指针可以指向链表中的任何节点或空节点。

构造这个链表的 [深拷贝](https://baike.baidu.com/item/%E6%B7%B1%E6%8B%B7%E8%B4%9D/22785317?fr=aladdin)。 深拷贝应该正好由 n 个 全新 节点组成，其中每个新节点的值都设为其对应的原节点的值。新节点的 next 指针和 random 指针也都应指向复制链表中的新节点，并使原链表和复制链表中的这些指针能够表示相同的链表状态。复制链表中的指针都不应指向原链表中的节点 。

例如，如果原链表中有 X 和 Y 两个节点，其中 X.random --> Y 。那么在复制链表中对应的两个节点 x 和 y ，同样有 x.random --> y 。

返回复制链表的头节点。

用一个由 n 个节点组成的链表来表示输入/输出中的链表。每个节点用一个 [val, random_index] 表示：

val：一个表示 Node.val 的整数。
random_index：随机指针指向的节点索引（范围从 0 到 n-1）；如果不指向任何节点，则为  null 。
你的代码 只 接受原链表的头节点 head 作为传入参数。

```go
/**
 * Definition for a Node.
 * type Node struct {
 *     Val int
 *     Next *Node
 *     Random *Node
 * }
 */

func copyRandomList(head *Node) *Node {
    curr := head
    // 很妙的解法，原先A->B->C，先复制一份节点为A->A'->B->B'->C->C'
    for curr != nil {
        curr.Next = &Node{Val: curr.Val, Next: curr.Next}
        curr = curr.Next.Next
    }
    curr = head
    // 接上random节点
    for curr != nil {
        // 如果原先节点存在random节点
        if curr.Random != nil {
            // 新的random节点一定在原先的random节点后面
            curr.Next.Random = curr.Random.Next
        }
        curr = curr.Next.Next
    }

    dummy := &Node{}
    ncurr := dummy
    // 将链表拆分
    curr = head
    for curr != nil {
        ncurr.Next = curr.Next
        ncurr = ncurr.Next

        curr.Next = curr.Next.Next
        curr = curr.Next
    }

    return dummy.Next
}
```

### 328. 奇偶链表

[328. 奇偶链表](https://leetcode-cn.com/problems/odd-even-linked-list/)
给定单链表的头节点 head ，将所有索引为奇数的节点和索引为偶数的节点分别组合在一起，然后返回重新排序的列表。

第一个节点的索引被认为是 奇数 ， 第二个节点的索引为 偶数 ，以此类推。

请注意，偶数组和奇数组内部的相对顺序应该与输入时保持一致。

你必须在 O(1) 的额外空间复杂度和 O(n) 的时间复杂度下解决这个问题。

```java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *     int val;
 *     ListNode next;
 *     ListNode(int x) { val = x; }
 * }
 */
class Solution {
    public ListNode oddEvenList(ListNode head) {
        if (head == null || head.next == null || head.next.next == null) {
            return head;
        }
        
        ListNode temp, tempNode = null;
        ListNode newHead = head;
        // 奇数位指针和偶数位指针
        ListNode odd = newHead, even = newHead.next;
        // 一开始是奇数
        boolean isOdd = true;
        head = even.next;
        
        if (head.next == null) {
            temp = odd.next;
            odd.next = head;
            temp.next = head.next;
            head.next = temp;
            
            return odd;
        }
           
        while (head != null) {
            temp = head.next;
            head.next = null;
            
            // 如果是奇数
            if (isOdd) {
                tempNode = odd.next;
                odd.next = head;
                odd = odd.next;
                odd.next = tempNode;
            } else {
                even.next = head;
                even = even.next;
            }
            
            isOdd = !isOdd;
            head = temp;
        }
        
        return newHead;
    }
}
```

### 83. 删除排序链表中的重复元素

[83. 删除排序链表中的重复元素](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list/)
给定一个已排序的链表的头 head ， 删除所有重复的元素，使每个元素只出现一次 。返回 已排序的链表 。

```java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *     int val;
 *     ListNode next;
 *     ListNode(int x) { val = x; }
 * }
 */
class Solution {
    public ListNode deleteDuplicates(ListNode head) {
        if (head == null || head.next == null) {
            return head;
        }
        
        ListNode p = head, q = head.next;
        
        while (q != null) {
            if (q.val == p.val) {
                q = q.next;
                
                if (q == null) {
                    p.next = null;
                }
                
                continue;
            }
            
            p.next = q;
            p = q;
            q = q.next;
        }
        
        return head;
    }
}
```

### 82. 删除排序链表中的重复元素 II

[82. 删除排序链表中的重复元素 II](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list-ii/)
给定一个已排序的链表的头 head ， 删除原始链表中所有重复数字的节点，只留下不同的数字 。返回 已排序的链表 。

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    dummy := &ListNode{Val: -101}
    dummy.Next = head
    curr := dummy

    for curr.Next != nil && curr.Next.Next != nil {
        if curr.Next.Val == curr.Next.Next.Val {
            x := curr.Next.Val 
            for curr.Next != nil && curr.Next.Val == x {
                curr.Next = curr.Next.Next
            }
        } else {
            curr = curr.Next
        }
    }

    return dummy.Next
}
```