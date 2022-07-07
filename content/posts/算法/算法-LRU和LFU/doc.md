---
author: "Lambert Xiao"
title: "算法-LRU和LFU"
date: "2022-03-13"
summary: "经典面试题了属实是"
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 146. LRU 缓存

[146. LRU 缓存](https://leetcode-cn.com/problems/lru-cache/)
请你设计并实现一个满足  [LRU (最近最少使用) 缓存](https://baike.baidu.com/item/LRU) 约束的数据结构。

实现 LRUCache 类：

- LRUCache(int capacity) 以 正整数 作为容量 capacity 初始化 LRU 缓存
- int get(int key) 如果关键字 key 存在于缓存中，则返回关键字的值，否则返回 -1 。
- void put(int key, int value) 如果关键字 key 已经存在，则变更其数据值 value ；如果不存在，则向缓存中插入该组 key-value 。如果插入操作导致关键字数量超过 capacity ，则应该 逐出 最久未使用的关键字。

函数 get 和 put 必须以 O(1) 的平均时间复杂度运行。

```go
type LRUCache struct {
    capacity, size int
    nodes map[int]*DLinkedNode
    head, tail *DLinkedNode
}

type DLinkedNode struct {
    key, val int
    prev, next *DLinkedNode
}

func Constructor(capacity int) LRUCache {
    c := LRUCache{
        capacity: capacity,
        nodes: make(map[int]*DLinkedNode),
        head: &DLinkedNode{},
        tail: &DLinkedNode{},
    }
    c.head.next = c.tail
    c.tail.prev = c.head
    return c
}


func (c *LRUCache) Get(key int) int {
    node, ok := c.nodes[key]
    if !ok {
        return -1
    }

    c.moveToHead(node)
    return node.val
}


func (c *LRUCache) Put(key int, val int)  {
    old, ok := c.nodes[key]
    if !ok {
        node := &DLinkedNode{key: key, val: val}
        c.nodes[key] = node
        c.addToHead(node)

        c.size++
        if c.size > c.capacity {
            tail := c.removeTail()
            delete(c.nodes, tail.key)
            c.size--
        }   
    } else {
        old.val = val
        c.moveToHead(old)
    }
}

func (c *LRUCache) removeNode(node *DLinkedNode) {
    node.prev.next = node.next
    node.next.prev = node.prev
}

func (c *LRUCache) removeTail() *DLinkedNode {
    node := c.tail.prev
    c.removeNode(node)
    return node
}

func (c *LRUCache) moveToHead(node *DLinkedNode) {
    c.removeNode(node)
    c.addToHead(node)
}

func (c *LRUCache) addToHead(node *DLinkedNode) {
    node.prev = c.head
    node.next = c.head.next
    c.head.next.prev = node
    c.head.next = node
}
```

### 460. LFU 缓存

[460. LFU 缓存](https://leetcode-cn.com/problems/lfu-cache/)
请你为 [最不经常使用（LFU）](https://baike.baidu.com/item/%E7%BC%93%E5%AD%98%E7%AE%97%E6%B3%95)缓存算法设计并实现数据结构。

实现 LFUCache 类：

- LFUCache(int capacity) - 用数据结构的容量 capacity 初始化对象
- int get(int key) - 如果键 key 存在于缓存中，则获取键的值，否则返回 -1 。
- void put(int key, int value) - 如果键 key 已存在，则变更其值；如果键不存在，请插入键值对。当缓存达到其容量 capacity 时，则应该在插入新项之前，移除最不经常使用的项。在此问题中，当存在平局（即两个或更多个键具有相同使用频率）时，应该去除 最近最久未使用 的键。

为了确定最不常使用的键，可以为缓存中的每个键维护一个 使用计数器 。使用计数最小的键是最久未使用的键。

当一个键首次插入到缓存中时，它的使用计数器被设置为 1 (由于 put 操作)。对缓存中的键执行 get 或 put 操作，使用计数器的值将会递增。

函数 get 和 put 必须以 O(1) 的平均时间复杂度运行。

```go
type LFUCache struct {
	keyToVal    map[int]*Node
	freqToNodes map[int]*DoubleList
	capacity    int
	minFreq     int
}

func Constructor(capacity int) LFUCache {
    c := LFUCache{
        capacity: capacity,
        minFreq: 0,
        keyToVal: make(map[int]*Node),
        freqToNodes: make(map[int]*DoubleList),
    }
    return c
}

type Node struct {
	key  int
	val  int
	prev *Node
	next *Node
	freq int
}

func (c *LFUCache) Get(key int) int {
	node, ok := c.keyToVal[key]
	if !ok {
		return -1
	}

	c.increseFreq(node)
	return node.val
}

func (c *LFUCache) Put(key int, value int) {
    if c.capacity == 0 {
        return
    }
    
	// 1. 存在则调整节点的频率即可
	node, ok := c.keyToVal[key]
	if ok {
		node.val = value
		c.increseFreq(node)
		return
	}

	// 2. 判断capacity, 容量不足，删除最少访问的节点
	if len(c.keyToVal) == c.capacity {
		c.deleteMinFreqNodes()
	}

	// 3. 添加节点到双向链表和索引表
	node = &Node{key: key, val: value, freq: 1}
	c.keyToVal[key] = node

	if c.freqToNodes[node.freq] == nil {
		c.freqToNodes[node.freq] = NewDoubleList()
	}
	c.freqToNodes[node.freq].Add(node)
	c.minFreq = 1
}

func (c *LFUCache) increseFreq(node *Node) {
	originFreq := node.freq
	node.freq++
	// 1. 频率更新后，将节点从原来的频率链表中移除
	dl := c.freqToNodes[originFreq]
	// O(1)
	dl.Remove(node)

	// 2. 判断最低频率是否需要更新
	if dl.IsEmpty() && originFreq == c.minFreq {
		c.minFreq++
	}

	// 3. 将更新后的节点插入对应频率的链表的表头
	if c.freqToNodes[node.freq] == nil {
		c.freqToNodes[node.freq] = NewDoubleList()
	}
	c.freqToNodes[node.freq].Add(node)
}

func (c *LFUCache) deleteMinFreqNodes() {
	// 1. 移除最少访问节点，双向链表按时间排序，新的在头，旧的在尾
	dl := c.freqToNodes[c.minFreq]
	lastn := dl.Last()
	dl.Remove(lastn)
	// 2. 移除索引
	delete(c.keyToVal, lastn.key)
}

type DoubleList struct {
	head, tail *Node
}

func NewDoubleList() *DoubleList {
    head, tail := new(Node), new(Node)
    head.next, tail.prev = tail, head
	dl := &DoubleList{
		head: head, tail: tail,
	}
	return dl
}

func (dl *DoubleList) Add(node *Node) {
	prev, next := dl.head, dl.head.next
	prev.next, node.prev = node, prev
	next.prev, node.next = node, next
}

func (dl *DoubleList) Remove(node *Node) {
	prev, next := node.prev, node.next
	prev.next, next.prev = next, prev
	node.prev, node.next = nil, nil
}

func (dl *DoubleList) First() *Node {
	return dl.head.next
}
func (dl *DoubleList) Last() *Node {
	return dl.tail.prev
}

func (dl *DoubleList) IsEmpty() bool {
	return dl.head.next == dl.tail
}
```
