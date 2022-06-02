---
author: "Lambert Xiao"
title: "算法-全O(1)的数据结构"
date: "2022-03-23"
summary: "写在字节4面后"
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

面试字节跳动四面（严格来说是五面），最终得到的回复是技术没问题，但综合考虑选择了另外的候选人，呵呵哒。稍微复盘了下，一个可能是涨幅要的过多，一个可能是二本的学历对于我进大厂造成了影响，又或者可能是谈职业规划时，没让HR听到想要听到的。
总之，革命尚未成功，同志仍需努力！


## 432. 全 O(1) 的数据结构

[432. 全 O(1) 的数据结构](https://leetcode-cn.com/problems/all-oone-data-structure/)

请你设计一个用于存储字符串计数的数据结构，并能够返回计数最小和最大的字符串。

实现 AllOne 类：

- AllOne() 初始化数据结构的对象。
- inc(String key) 字符串 key 的计数增加 1 。如果数据结构中尚不存在 key ，那么插入计数为 1 的 key 。
- dec(String key) 字符串 key 的计数减少 1 。如果 key 的计数在减少后为 0 ，那么需要将这个 key 从数据结构中删除。测试用例保证：在减少计数前，key 存在于数据结构中。
- getMaxKey() 返回任意一个计数最大的字符串。如果没有元素存在，返回一个空字符串 "" 。
- getMinKey() 返回任意一个计数最小的字符串。如果没有元素存在，返回一个空字符串 "" 。


思路：

1. hash表存放key到Node的映射
2. 一个Node存放一批相同计数的key
3. 双向链表将所有的Node按照计数从小到大串联起来
4. 当某个key的计数增加或减少时，将key从当前的node中移除，并且在相邻的node中找到自己的容身之地（如果没有对应计数的node，则新建一个node）

```go
type AllOne struct {
    key2node map[string]*Node
    dl *DoubleList
}

type Node struct {
    prev, next *Node
    keys map[string]struct{}
    cnt int
}

func NewNode(cnt int) *Node {
    n := &Node{
        keys: make(map[string]struct{}), cnt: cnt,
    }
    return n
}
func (n *Node) AddKey(key string) {
    n.keys[key] = struct{}{}
}
func (n *Node) RemoveKey(key string) {
    delete(n.keys, key)
}
func (n *Node) IsEmpty() bool {
    return len(n.keys) == 0
}

func Constructor() AllOne {
    ao := AllOne{
        key2node: make(map[string]*Node),
        dl: NewDoubleList(),
    }
    return ao
}

func (ao *AllOne) Inc(key string)  {
    curr, ok := ao.key2node[key]
    if ok {
        next := curr.next

        if next == nil || next.cnt > curr.cnt + 1 {
            n := NewNode(curr.cnt + 1)
            n.AddKey(key)
            ao.key2node[key] = n
            ao.dl.InsertAfter(n, curr)
        } else {
            next.AddKey(key)
            ao.key2node[key] = next
        }
        curr.RemoveKey(key)
        if curr.IsEmpty() {
            ao.dl.Remove(curr)
        }
    } else {
        first := ao.dl.First()
        if first == nil || first.cnt > 1 {
            n := NewNode(1)
            n.AddKey(key)
            ao.key2node[key] = n
            ao.dl.Push(n)
        } else {
            first.AddKey(key)
            ao.key2node[key] = first
        }  
    }

    ao.dl.Print()
}


func (ao *AllOne) Dec(key string)  {
    curr := ao.key2node[key]
    if curr.cnt > 1 {
        prev := curr.prev
        if prev == nil || prev.cnt < curr.cnt - 1 {
            n := NewNode(curr.cnt - 1)
            n.AddKey(key)
            ao.key2node[key] = n
            ao.dl.InsertBefore(n, curr)
        } else {
            prev.AddKey(key)
            ao.key2node[key] = prev
        }
    } else {
        delete(ao.key2node, key)
    }
    curr.RemoveKey(key)
    if curr.IsEmpty() {
        ao.dl.Remove(curr)
    }
}


func (ao *AllOne) GetMaxKey() string {
    last := ao.dl.Last()
    if last != nil {
        for k := range last.keys {
            return k
        }
    }
    return ""
}

func (ao *AllOne) GetMinKey() string {
    first := ao.dl.First()
    if first != nil {
        for k := range first.keys {
            return k
        }
    }
    return ""
}

type DoubleList struct {
    head, tail *Node
}

func NewDoubleList() *DoubleList {
    head, tail := NewNode(-1), NewNode(10000000)
    head.next, tail.prev = tail, head
	dl := &DoubleList{
		head: head, tail: tail,
	}
    return dl
}

func (dl *DoubleList) Push(node *Node) {
    prev, next := dl.head, dl.head.next
	prev.next, node.prev = node, prev
	next.prev, node.next = node, next
}

func (dl *DoubleList) Remove(node *Node) {
    prev, next := node.prev, node.next
	prev.next, next.prev = next, prev
	node.prev, node.next = nil, nil
}

func (dl *DoubleList) InsertBefore(n, before *Node) {
    prev := before.prev
    before.prev, n.next = n, before
    prev.next, n.prev = n, prev
}

func (dl *DoubleList) InsertAfter(n, after *Node) {
    next := after.next
    after.next, n.prev = n, after
    n.next, next.prev = next, n
}

func (dl *DoubleList) First() *Node {
    if dl.IsEmpty() {
        return nil 
    }

    return dl.head.next
}

func (dl *DoubleList) Last() *Node {
    if dl.IsEmpty() {
        return nil 
    }

    return dl.tail.prev
}

func (dl *DoubleList) Print() {
    curr := dl.head.next
    for curr != dl.tail && curr != nil {
        curr = curr.next
    }
}

func (dl *DoubleList) IsEmpty() bool {
    return dl.head.next == dl.tail
}
```
