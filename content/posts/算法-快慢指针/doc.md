---
author: "Lambert Xiao"
title: "算法-快慢指针"
date: "2022-03-13"
summary: ""
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

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