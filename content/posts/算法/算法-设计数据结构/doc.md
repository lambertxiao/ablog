---
author: "Lambert Xiao"
title: "算法-设计数据结构"
date: "2022-04-04"
summary: "双向队列，跳表等"
tags: ["算法", "数据结构"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 622. 设计循环队列

[622. 设计循环队列](https://leetcode-cn.com/problems/design-circular-queue/)

设计你的循环队列实现。 循环队列是一种线性数据结构，其操作表现基于 FIFO（先进先出）原则并且队尾被连接在队首之后以形成一个循环。它也被称为“环形缓冲器”。

循环队列的一个好处是我们可以利用这个队列之前用过的空间。在一个普通队列里，一旦一个队列满了，我们就不能插入下一个元素，即使在队列前面仍有空间。但是使用循环队列，我们能使用这些空间去存储新的值。

你的实现应该支持如下操作：

- MyCircularQueue(k): 构造器，设置队列长度为 k 。
- Front: 从队首获取元素。如果队列为空，返回 -1 。
- Rear: 获取队尾元素。如果队列为空，返回 -1 。
- enQueue(value): 向循环队列插入一个元素。如果成功插入则返回真。
- deQueue(): 从循环队列中删除一个元素。如果成功删除则返回真。
- isEmpty(): 检查循环队列是否为空。
- isFull(): 检查循环队列是否已满。

```go
type MyCircularQueue struct {
    data []int
    size int
    headIdx int
    count int
}


func Constructor(k int) MyCircularQueue {
    q := MyCircularQueue{
        data: make([]int, k),
        size: k,
        headIdx: 0,
        count: 0,
    }
    return q
}


func (q *MyCircularQueue) EnQueue(value int) bool {
    if q.count == q.size {
        return false
    }

    insertIdx := (q.headIdx + q.count) % q.size
    q.data[insertIdx] = value
    q.count++
    return true
}


func (q *MyCircularQueue) DeQueue() bool {
    if q.count == 0 { return false }

    q.headIdx = (q.headIdx + 1) % q.size
    q.count--
    return true
}


func (q *MyCircularQueue) Front() int {
    if q.count == 0 { return -1 }
    return q.data[q.headIdx]
}


func (q *MyCircularQueue) Rear() int {
    if q.count == 0 { return -1 }
    return q.data[(q.headIdx + q.count - 1) % q.size]
}


func (q *MyCircularQueue) IsEmpty() bool {
    return q.count == 0
}


func (q *MyCircularQueue) IsFull() bool {
    return q.count == q.size
}


/**
 * Your MyCircularQueue object will be instantiated and called as such:
 * obj := Constructor(k);
 * param_1 := obj.EnQueue(value);
 * param_2 := obj.DeQueue();
 * param_3 := obj.Front();
 * param_4 := obj.Rear();
 * param_5 := obj.IsEmpty();
 * param_6 := obj.IsFull();
 */
```

### 705. 设计哈希集合

[705. 设计哈希集合](https://leetcode-cn.com/problems/design-hashset/)

不使用任何内建的哈希表库设计一个哈希集合（HashSet）。

实现 MyHashSet 类：

- void add(key) 向哈希集合中插入值 key 。
- bool contains(key) 返回哈希集合中是否存在这个值 key 。
- void remove(key) 将给定值 key 从哈希集合中删除。如果哈希集合中没有这个值，什么也不做。

```go
type MyHashSet struct {
    data []int
}

func Constructor() MyHashSet {
    hs := MyHashSet{
        data: make([]int, 40000),
    }
    return hs
}


func (s *MyHashSet) Add(key int)  {
    // 先分成32个桶，桶里用一个int的32位表示32个值int为4个字节，有32位可以用来表示状态
    idx, offset := s.getLoc(key)
    // 将0000 0000 0000 0000 0000 0000 0000 0001其中最后一位1移动到对应位置
    s.data[idx] |= 1 << offset 
}

func (s *MyHashSet) getLoc(key int) (int, int) {
    bucketIdx := key / 32
    offset := key % 32
    return bucketIdx, offset
}

func (s *MyHashSet) Remove(key int)  {
    idx, offset := s.getLoc(key)
    // 将最后一位1移动到目标位之后，～按位取反，再&上，从而将对应位置上的1清掉
    v := ^(1 << offset)
    s.data[idx] &= ^(1 << offset)
}


func (s *MyHashSet) Contains(key int) bool {
    idx, offset := s.getLoc(key)
    v := s.data[idx]
    return (v >> offset) & 1 == 1
}


/**
 * Your MyHashSet object will be instantiated and called as such:
 * obj := Constructor();
 * obj.Add(key);
 * obj.Remove(key);
 * param_3 := obj.Contains(key);
 */
```

### 706. 设计哈希映射
[706. 设计哈希映射](https://leetcode-cn.com/problems/design-hashmap/)

不使用任何内建的哈希表库设计一个哈希映射（HashMap）。

实现 MyHashMap 类：

- MyHashMap() 用空映射初始化对象
- void put(int key, int value) 向 HashMap 插入一个键值对 (key, value) 。如果 key 已经存在于映射中，则更新其对应的- 值 value 。
- int get(int key) 返回特定的 key 所映射的 value ；如果映射中不包含 key 的映射，返回 -1 。
- void remove(key) 如果映射中存在 key 的映射，则移除 key 和它所对应的 value 。

```go
type MyHashMap struct {
    data []list.List
}

func Constructor() MyHashMap {
    m := MyHashMap{
        data: make([]list.List, 769),
    }
    return m
}

type node struct {
    key, value int
}

func (m *MyHashMap) Put(key int, value int)  {
    h := m.hash(key)

    for e := m.data[h].Front(); e != nil; e = e.Next() {
        if et := e.Value.(node); et.key == key {
            e.Value = node{key, value}
            return
        }
    }
    m.data[h].PushBack(node{key, value})
}

func (m *MyHashMap) hash(key int) int {
    return key % 769
}

func (m *MyHashMap) Get(key int) int {
    h := m.hash(key)
    for e := m.data[h].Front(); e != nil; e = e.Next() {
        if et := e.Value.(node); et.key == key {
            return et.value
        }
    }
    return -1
}

func (m *MyHashMap) Remove(key int)  {
    h := m.hash(key)
    for e := m.data[h].Front(); e != nil; e = e.Next() {
        if e.Value.(node).key == key {
            m.data[h].Remove(e)
        }
    }
}

/**
 * Your MyHashMap object will be instantiated and called as such:
 * obj := Constructor();
 * obj.Put(key,value);
 * param_2 := obj.Get(key);
 * obj.Remove(key);
 */
```

### 641. 设计循环双端队列

[641. 设计循环双端队列](https://leetcode-cn.com/problems/design-circular-deque/)

设计实现双端队列。

实现 MyCircularDeque 类:

- MyCircularDeque(int k) ：构造函数,双端队列最大为 k 。
- boolean insertFront()：将一个元素添加到双端队列头部。 如果操作成功返回 true ，否则返回 false 。
- boolean insertLast() ：将一个元素添加到双端队列尾部。如果操作成功返回 true ，否则返回 false 。
- boolean deleteFront() ：从双端队列头部删除一个元素。 如果操作成功返回 true ，否则返回 false 。
- boolean deleteLast() ：从双端队列尾部删除一个元素。如果操作成功返回 true ，否则返回 false 。
- int getFront() )：从双端队列头部获得一个元素。如果双端队列为空，返回 -1 。
- int getRear() ：获得双端队列的最后一个元素。 如果双端队列为空，返回 -1 。
- boolean isEmpty() ：若双端队列为空，则返回 true ，否则返回 false  。
- boolean isFull() ：若双端队列满了，则返回 true ，否则返回 false 。

```go
type MyCircularDeque struct {
    head, tail *Node
    cap, size int
}

type Node struct {
    prev, next *Node
    val int
}

func Constructor(k int) MyCircularDeque {
    head, tail := new(Node), new(Node)
    head.next = tail
    tail.prev = head

    q := MyCircularDeque{
        cap: k,
        head: head,
        tail: tail,
    }
    return q
}


func (q *MyCircularDeque) InsertFront(value int) bool {
    if q.IsFull() {
        return false
    }

    q.size++
    node := &Node{val: value}
    head := q.head
    next := head.next
    head.next, node.prev = node, head
    node.next, next.prev = next, node
    return true
}


func (q *MyCircularDeque) InsertLast(value int) bool {
    if q.IsFull() {
        return false
    }

    q.size++

    node := &Node{val: value}
    tail := q.tail
    prev := tail.prev
    prev.next, node.prev = node, prev
    tail.prev, node.next = node, tail
    return true
}


func (q *MyCircularDeque) DeleteFront() bool {
    if q.IsEmpty() {
        return false
    }

    q.size--
    head := q.head
    head.next = head.next.next
    head.next.prev = head
    return true
}


func (q *MyCircularDeque) DeleteLast() bool {
    if q.IsEmpty() {
        return false
    }

    q.size--
    tail := q.tail
    tail.prev = tail.prev.prev
    tail.prev.next = tail
    return true
}


func (q *MyCircularDeque) GetFront() int {
    if q.IsEmpty() {
        return -1
    }

    return q.head.next.val
}


func (q *MyCircularDeque) GetRear() int {
    if q.IsEmpty() {
        return -1
    }

    return q.tail.prev.val
}


func (q *MyCircularDeque) IsEmpty() bool {
    return q.head.next == q.tail 
}


func (q *MyCircularDeque) IsFull() bool {
    return q.size == q.cap 
}

/**
 * Your MyCircularDeque object will be instantiated and called as such:
 * obj := Constructor(k);
 * param_1 := obj.InsertFront(value);
 * param_2 := obj.InsertLast(value);
 * param_3 := obj.DeleteFront();
 * param_4 := obj.DeleteLast();
 * param_5 := obj.GetFront();
 * param_6 := obj.GetRear();
 * param_7 := obj.IsEmpty();
 * param_8 := obj.IsFull();
 */
```

### 1206. 设计跳表

[1206. 设计跳表](https://leetcode-cn.com/problems/design-skiplist/)

不使用任何库函数，设计一个 跳表 。

跳表 是在 O(log(n)) 时间内完成增加、删除、搜索操作的数据结构。跳表相比于树堆与红黑树，其功能与性能相当，并且跳表的代码长度相较下更短，其设计思想与链表相似。

跳表中有很多层，每一层是一个短的链表。在第一层的作用下，增加、删除和搜索操作的时间复杂度不超过 O(n)。跳表的每一个操作的平均时间复杂度是 O(log(n))，空间复杂度是 O(n)。

了解更多 : https://en.wikipedia.org/wiki/Skip_list

在本题中，你的设计应该要包含这些函数：

- bool search(int target) : 返回target是否存在于跳表中。
- void add(int num): 插入一个元素到跳表。
- bool erase(int num): 在跳表中删除一个值，如果 num 不存在，直接返回false. 如果存在多个 num ，删除其中任意一个即可。

注意，跳表中可能存在多个相同的值，你的代码需要处理这种情况。


```go
type Skiplist struct {
    head *Node
    prevNodes []*Node // 存放插入过程中需要用到的临时节点
    maxLevel int
}

type Node struct {
    val int
    next, down *Node
}

func Constructor() Skiplist {
    head := &Node{val: -1}
    sl := Skiplist{
        head: head,
        prevNodes: make([]*Node, 64),
        maxLevel: 16,
    }
    return sl
}


func (sl *Skiplist) Search(target int) bool {
    curr := sl.head
    for curr != nil {
        // 在同一层上找
        for curr.next != nil && curr.next.val < target {
            curr = curr.next
        }
        if curr.next != nil && curr.next.val == target {
            return true
        }
        curr = curr.down
    }
    return false
}


func (sl *Skiplist) Add(num int)  {
    level := -1
    curr := sl.head
    for curr != nil {
        for curr.next != nil && curr.next.val < num {
            curr = curr.next
        }
        level++
        sl.prevNodes[level] = curr
        curr = curr.down
    }

    // 从最底层level往上，对于待插入的节点，决定是否插入在某个level上
    insertUp := true
    var downNode *Node

    for insertUp && level >= 0 {
        prevNode := sl.prevNodes[level]
        level--
        prevNode.next = &Node{val: num, next: prevNode.next, down: downNode }
        downNode = prevNode.next

        // 随机决定是否在上一层插入node
        insertUp = rand.Intn(2) == 0
    }

    if insertUp {
        newhead := &Node{val: num, next: nil, down: downNode }
        sl.head =  &Node{val: -1, next: newhead, down: sl.head}
    }
}


func (sl *Skiplist) Erase(num int) bool {
    exist := false
    curr := sl.head

    for curr != nil {
        for curr.next != nil && curr.next.val < num {
            curr = curr.next
        }
        if curr.next != nil && curr.next.val == num {
            exist = true
            curr.next = curr.next.next
        }
        curr = curr.down
    }
    return exist
}


/**
 * Your Skiplist object will be instantiated and called as such:
 * obj := Constructor();
 * param_1 := obj.Search(target);
 * obj.Add(num);
 * param_3 := obj.Erase(num);
 */
```