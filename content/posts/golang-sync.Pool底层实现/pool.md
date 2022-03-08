---
author: "Lambert Xiao"
title: "Golang-Sync.Pool底层实现机制"
date: "2022-03-08"
summary: "sync.Pool在项目中被频繁用到，那么它底下是怎么实现的呢"
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
    image: "/cover/golang-sync.Pool底层实现.png"
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

咋一看，完全看不出来设计思路，不急，我们看看两个成员函数的实现。

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
