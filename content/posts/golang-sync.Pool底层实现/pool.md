---
author: "Lambert Xiao"
title: "Golang-Sync.Pool底层结构"
date: "2022-03-08"
summary: "sync.Pool在项目中被频繁用到，那么它底下是怎么实现的呢"
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/golang-syncpool.png"
---

## sync.Pool的作用

一般地，对于一些频繁创建-销毁对象的场景，为了降低GC的压力，会将使用完的对象缓存起来，而不是直接让GC给回收掉。在golang中，提供了`sync.Pool`这个类，很方便地让我们实现对一个对象的复用

## sync.Pool的用法

pool的用法十分简单，只需要在声明pool对象的时候给入New函数，New函数可以让我们自定义需要生成一个什么对象

```go
type Fool struct {}

pool := sync.Pool{
    New: func() interface{} {
        return new(Fool)
    }
}

foo := pool.Get().(*Fool)
pool.Put(foo)
```

## sync.Pool的底层结构

让我们打开源码，一窥pool的底层实现原理

> /usr/local/go/src/sync/pool.go

```go
type Pool struct {
	noCopy noCopy

	local     unsafe.Pointer // local fixed-size per-P pool, actual type is [P]poolLocal
	localSize uintptr        // size of the local array

	victim     unsafe.Pointer // local from previous cycle
	victimSize uintptr        // size of victims array

	// New optionally specifies a function to generate
	// a value when Get would otherwise return nil.
	// It may not be changed concurrently with calls to Get.
	New func() interface{}
}
```

从注释上我们可以看出，`local`其实是一个数组，类型为`[P]poolLocal`, 而数组的长度就是当前P(MPG模型里的P)的数量，所以，对应每一个P，Pool里都有一个poolLocal的本地池，由于P一个时刻只能和一个M绑定，所以访问poolLocal时，可以做到无锁访问。`localSize` 的值也就明显是P的数量。

`victim` 和 `victimSize` 咋一看，完全看不出来设计思路，不急，我们先看看两个成员函数的实现。


### Get操作

先从Get方法入手，查看一个对象是如何从池中给到我们的

```go
// Get selects an arbitrary item from the Pool, removes it from the
// Pool, and returns it to the caller.
// Get may choose to ignore the pool and treat it as empty.
// Callers should not assume any relation between values passed to Put and
// the values returned by Get.
//
// If Get would otherwise return nil and p.New is non-nil, Get returns
// the result of calling p.New.
func (p *Pool) Get() interface{} {
	if race.Enabled {
		race.Disable()
	}
	l, pid := p.pin()
	x := l.private
	l.private = nil
	if x == nil {
		// Try to pop the head of the local shard. We prefer
		// the head over the tail for temporal locality of
		// reuse.
		x, _ = l.shared.popHead()
		if x == nil {
			x = p.getSlow(pid)
		}
	}
	runtime_procUnpin()
	if race.Enabled {
		race.Enable()
		if x != nil {
			race.Acquire(poolRaceAddr(x))
		}
	}
	if x == nil && p.New != nil {
		x = p.New()
	}
	return x
}
```

1. 利用p.pin()，将当前的goroutine固定在P上，并且了禁用了抢占，同时得到来poolLocal
2. 检查poolLocal的private是否为空，不为空则会被拿来用
3. 当private为空，会从shared的头部获取一个元素
4. 如果还是获取不到，则会去其他P的对象池里拿元素

```go
func (c *poolChain) popHead() (interface{}, bool) {
	d := c.head
	for d != nil {
		if val, ok := d.popHead(); ok {
			return val, ok
		}
		// There may still be unconsumed elements in the
		// previous dequeue, so try backing up.
		d = loadPoolChainElt(&d.prev)
	}
	return nil, false
}
```

1. 从head指向的poolDequeue中获取元素

```go
func (p *Pool) getSlow(pid int) interface{} {
	// See the comment in pin regarding ordering of the loads.
	size := runtime_LoadAcquintptr(&p.localSize) // load-acquire
	locals := p.local                            // load-consume
	// Try to steal one element from other procs.
	for i := 0; i < int(size); i++ {
		l := indexLocal(locals, (pid+i+1)%int(size))
		if x, _ := l.shared.popTail(); x != nil {
			return x
		}
	}

	// Try the victim cache. We do this after attempting to steal
	// from all primary caches because we want objects in the
	// victim cache to age out if at all possible.
	size = atomic.LoadUintptr(&p.victimSize)
	if uintptr(pid) >= size {
		return nil
	}
	locals = p.victim
	l := indexLocal(locals, pid)
	if x := l.private; x != nil {
		l.private = nil
		return x
	}
	for i := 0; i < int(size); i++ {
		l := indexLocal(locals, (pid+i)%int(size))
		if x, _ := l.shared.popTail(); x != nil {
			return x
		}
	}

	// Mark the victim cache as empty for future gets don't bother
	// with it.
	atomic.StoreUintptr(&p.victimSize, 0)

	return nil
}
```

1. 尝试从其他P的shared池中获取元素

```go
func (c *poolChain) popTail() (interface{}, bool) {
	d := loadPoolChainElt(&c.tail)
	if d == nil {
		return nil, false
	}

	for {
		// It's important that we load the next pointer
		// *before* popping the tail. In general, d may be
		// transiently empty, but if next is non-nil before
		// the pop and the pop fails, then d is permanently
		// empty, which is the only condition under which it's
		// safe to drop d from the chain.
		d2 := loadPoolChainElt(&d.next)

		if val, ok := d.popTail(); ok {
			return val, ok
		}

		if d2 == nil {
			// This is the only dequeue. It's empty right
			// now, but could be pushed to in the future.
			return nil, false
		}

		// The tail of the chain has been drained, so move on
		// to the next dequeue. Try to drop it from the chain
		// so the next pop doesn't have to look at the empty
		// dequeue again.
		if atomic.CompareAndSwapPointer((*unsafe.Pointer)(unsafe.Pointer(&c.tail)), unsafe.Pointer(d), unsafe.Pointer(d2)) {
			// We won the race. Clear the prev pointer so
			// the garbage collector can collect the empty
			// dequeue and so popHead doesn't back up
			// further than necessary.
			storePoolChainElt(&d2.prev, nil)
		}
		d = d2
	}
}
```

将`poolLocal`的结构摆开，看看里面有什么

```go
type poolLocal struct {
	poolLocalInternal

	// Prevents false sharing on widespread platforms with
	// 128 mod (cache line size) = 0 .
	pad [128 - unsafe.Sizeof(poolLocalInternal{})%128]byte
}

// Local per-P Pool appendix.
type poolLocalInternal struct {
	private interface{} // Can be used only by the respective P.
	shared  poolChain   // Local P can pushHead/popHead; any P can popTail.
}
```

1. poolLocalInternal上的private是P私有的，在Get的时候会被优先获取
2. shared是个双向队列，本地的P能从head处插入及获取元素，而其余的P只能拿尾部的内容


下面打开`poolChain`的结构

```go
// poolChain is a dynamically-sized version of poolDequeue.
//
// This is implemented as a doubly-linked list queue of poolDequeues
// where each dequeue is double the size of the previous one. Once a
// dequeue fills up, this allocates a new one and only ever pushes to
// the latest dequeue. Pops happen from the other end of the list and
// once a dequeue is exhausted, it gets removed from the list.
type poolChain struct {
	// head is the poolDequeue to push to. This is only accessed
	// by the producer, so doesn't need to be synchronized.
	head *poolChainElt

	// tail is the poolDequeue to popTail from. This is accessed
	// by consumers, so reads and writes must be atomic.
	tail *poolChainElt
}

type poolChainElt struct {
	poolDequeue

	// next and prev link to the adjacent poolChainElts in this
	// poolChain.
	//
	// next is written atomically by the producer and read
	// atomically by the consumer. It only transitions from nil to
	// non-nil.
	//
	// prev is written atomically by the consumer and read
	// atomically by the producer. It only transitions from
	// non-nil to nil.
	next, prev *poolChainElt
}
```

可以看出`poolChain`本身是个双端队列，持有着队列的head和tail两个指针，而poolChain队列里的每个Item则是个poolDequeue（环形队列），我们知道poolDequeue是固定长度的，但poolChain又是动态长度的，poolChain通过双向链表的形式将poolDequeue串起来使用。

### Put操作

来看sync.Pool的Put操作

```go
// Put adds x to the pool.
func (p *Pool) Put(x interface{}) {
	if x == nil {
		return
	}
	if race.Enabled {
		if fastrand()%4 == 0 {
			// Randomly drop x on floor.
			return
		}
		race.ReleaseMerge(poolRaceAddr(x))
		race.Disable()
	}
	l, _ := p.pin()
	if l.private == nil {
		l.private = x
		x = nil
	}
	if x != nil {
		l.shared.pushHead(x)
	}
	runtime_procUnpin()
	if race.Enabled {
		race.Enable()
	}
}
```

1. 一样地，将当前的P和Goroutine固定住
2. 检查poolLocal的private是否为空，为空则赋值上回收的对象
3. 如果x没被private回收，则投放到shared中

```go
func (c *poolChain) pushHead(val interface{}) {
	d := c.head
	if d == nil {
		// Initialize the chain.
		const initSize = 8 // Must be a power of 2
		d = new(poolChainElt)
		d.vals = make([]eface, initSize)
		c.head = d
		storePoolChainElt(&c.tail, d)
	}

	if d.pushHead(val) {
		return
	}

	// The current dequeue is full. Allocate a new one of twice
	// the size.
	newSize := len(d.vals) * 2
	if newSize >= dequeueLimit {
		// Can't make it any bigger.
		newSize = dequeueLimit
	}

	d2 := &poolChainElt{prev: d}
	d2.vals = make([]eface, newSize)
	c.head = d2
	storePoolChainElt(&d.next, d2)
	d2.pushHead(val)
}
```

1. poolChain执行pushHead时，如果poolChain还是空的，则初始化一个size为8的poolDequeue
2. 将回收的元素放入head指向的poolDequeue中
3. 如果head指向的poolDequeue已满了，则创建一个新的poolDequeue，并且缓冲区大小为原来的两倍
4. 将新建的poolDequeue插入头部

### sync.Pool中的元素什么时候被回收

GC时

```go
func init() {
	runtime_registerPoolCleanup(poolCleanup)
}
```

在sync.Pool的init中，注册了GC的Hook

```go
func poolCleanup() {
	// This function is called with the world stopped, at the beginning of a garbage collection.
	// It must not allocate and probably should not call any runtime functions.

	// Because the world is stopped, no pool user can be in a
	// pinned section (in effect, this has all Ps pinned).

	// Drop victim caches from all pools.
	for _, p := range oldPools {
		p.victim = nil
		p.victimSize = 0
	}

	// Move primary cache to victim cache.
	for _, p := range allPools {
		p.victim = p.local
		p.victimSize = p.localSize
		p.local = nil
		p.localSize = 0
	}

	// The pools with non-empty primary caches now have non-empty
	// victim caches and no pools have primary caches.
	oldPools, allPools = allPools, nil
}
```
### 总结

1. 关键思想是对象的复用，避免重复创建、销毁。减轻 GC 的压力。
2. sync.Pool 是协程安全的
3. 不要对 Get 得到的对象有任何假设，默认Get到对象是一个空对象，Get之后手动初始化。
4. 好的实践是：Put操作执行前将对象“清空”，并且确保对象被Put进去之后不要有任何的指针引用再次使用
5. Pool 里对象的生命周期受 GC 影响，不适合于做连接池，因为连接池需要自己管理对象的生命周期。
6. Pool 不可以指定⼤⼩，⼤⼩只受制于 GC 临界值。
7. procPin 将 G 和 P 绑定，防止 G 被抢占。在绑定期间，GC 无法清理缓存的对象。
8. sync.Pool 的设计理念，包括：无锁、操作对象隔离、原子操作代替锁、行为隔离——链表、Victim Cache 降低 GC 开销。

### 细节备注

```go
// pin pins the current goroutine to P, disables preemption and
// returns poolLocal pool for the P and the P's id.
// Caller must call runtime_procUnpin() when done with the pool.
func (p *Pool) pin() (*poolLocal, int) {
	// 将goroutine固定里p上，并拿到里p的id
	pid := runtime_procPin()
	// In pinSlow we store to local and then to localSize, here we load in opposite order.
	// Since we've disabled preemption, GC cannot happen in between.
	// Thus here we must observe local at least as large localSize.
	// We can observe a newer/larger local, it is fine (we must observe its zero-initialized-ness).
	s := runtime_LoadAcquintptr(&p.localSize) // load-acquire
	l := p.local                              // load-consume
	if uintptr(pid) < s {
		return indexLocal(l, pid), pid
	}
	return p.pinSlow()
}
```

runtime_procPin方法实际上是对应以下函数

```go
//go:linkname sync_runtime_procPin sync.runtime_procPin
//go:nosplit
func sync_runtime_procPin() int {
	return procPin()
}

//go:nosplit
func procPin() int {
	_g_ := getg() // 获取了当前的G
	mp := _g_.m

	mp.locks++ // 这里M的locks自增
	return int(mp.p.ptr().id)
}
```
