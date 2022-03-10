---
author: "Lambert Xiao"
title: "Golang-实现限流器"
date: "2022-03-08"
summary: "麻了呀，面试问到限流器相关的知识答不出来"
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/golang-实现限流器.png"
---

今天面试字节，由于简历里写了限流器相关的项目经验，被要求使用代码实现一个限流器，当时冷不丁来这一下，没做出来，以及博客，纪念我死去的面试

## 限流器的作用

限流器常用来限制服务的访问次数，结合自身的业务逻辑，可以实现在可以维度去控制client的访问频次，超过规定的频次后可以直接拒绝访问

## 常见限流器的实现方案

- 令牌桶

## 常见的限流器库

以 `github.com/juju/ratelimit` 库为例，看看实现一个限流器需要具备哪些基本API


```go
// Bucket represents a token bucket that fills at a predetermined rate.
// Methods on Bucket may be called concurrently.
type Bucket struct {
	clock Clock

	// startTime holds the moment when the bucket was
	// first created and ticks began.
	startTime time.Time

	// capacity holds the overall capacity of the bucket.
	capacity int64

	// quantum holds how many tokens are added on
	// each tick.
	quantum int64

	// fillInterval holds the interval between each tick.
	fillInterval time.Duration

	// mu guards the fields below it.
	mu sync.Mutex

	// availableTokens holds the number of available
	// tokens as of the associated latestTick.
	// It will be negative when there are consumers
	// waiting for tokens.
	availableTokens int64

	// latestTick holds the latest tick for which
	// we know the number of tokens in the bucket.
	latestTick int64
}
```

1. 桶里记录了当前的时钟，以及桶创建的时间
2. capacit表示桶里总的令牌数量
3. quantum表示每经过一个tick会放入的令牌数
4. fillInterval表示一个tick的时间长度
5. mu用来支持多协程访问
6. availableTokens记录当前可用的令牌数
7. latestTick记录上一个tick的时间


```go
// NewBucket returns a new token bucket that fills at the
// rate of one token every fillInterval, up to the given
// maximum capacity. Both arguments must be
// positive. The bucket is initially full.
func NewBucket(fillInterval time.Duration, capacity int64) *Bucket {
	return NewBucketWithClock(fillInterval, capacity, nil)
}

// NewBucketWithClock is identical to NewBucket but injects a testable clock
// interface.
func NewBucketWithClock(fillInterval time.Duration, capacity int64, clock Clock) *Bucket {
	return NewBucketWithQuantumAndClock(fillInterval, capacity, 1, clock)
}

// rateMargin specifes the allowed variance of actual
// rate from specified rate. 1% seems reasonable.
const rateMargin = 0.01

// NewBucketWithRate returns a token bucket that fills the bucket
// at the rate of rate tokens per second up to the given
// maximum capacity. Because of limited clock resolution,
// at high rates, the actual rate may be up to 1% different from the
// specified rate.
func NewBucketWithRate(rate float64, capacity int64) *Bucket {
	return NewBucketWithRateAndClock(rate, capacity, nil)
}

// NewBucketWithRateAndClock is identical to NewBucketWithRate but injects a
// testable clock interface.
func NewBucketWithRateAndClock(rate float64, capacity int64, clock Clock) *Bucket {
	// Use the same bucket each time through the loop
	// to save allocations.
	tb := NewBucketWithQuantumAndClock(1, capacity, 1, clock)
	for quantum := int64(1); quantum < 1<<50; quantum = nextQuantum(quantum) {
		fillInterval := time.Duration(1e9 * float64(quantum) / rate)
		if fillInterval <= 0 {
			continue
		}
		tb.fillInterval = fillInterval
		tb.quantum = quantum
		if diff := math.Abs(tb.Rate() - rate); diff/rate <= rateMargin {
			return tb
		}
	}
	panic("cannot find suitable quantum for " + strconv.FormatFloat(rate, 'g', -1, 64))
}

// nextQuantum returns the next quantum to try after q.
// We grow the quantum exponentially, but slowly, so we
// get a good fit in the lower numbers.
func nextQuantum(q int64) int64 {
	q1 := q * 11 / 10
	if q1 == q {
		q1++
	}
	return q1
}

// NewBucketWithQuantum is similar to NewBucket, but allows
// the specification of the quantum size - quantum tokens
// are added every fillInterval.
func NewBucketWithQuantum(fillInterval time.Duration, capacity, quantum int64) *Bucket {
	return NewBucketWithQuantumAndClock(fillInterval, capacity, quantum, nil)
}

// NewBucketWithQuantumAndClock is like NewBucketWithQuantum, but
// also has a clock argument that allows clients to fake the passing
// of time. If clock is nil, the system clock will be used.
func NewBucketWithQuantumAndClock(fillInterval time.Duration, capacity, quantum int64, clock Clock) *Bucket {
	if clock == nil {
		clock = realClock{}
	}
	if fillInterval <= 0 {
		panic("token bucket fill interval is not > 0")
	}
	if capacity <= 0 {
		panic("token bucket capacity is not > 0")
	}
	if quantum <= 0 {
		panic("token bucket quantum is not > 0")
	}
	return &Bucket{
		clock:           clock,
		startTime:       clock.Now(),
		latestTick:      0,
		fillInterval:    fillInterval,
		capacity:        capacity,
		quantum:         quantum,
		availableTokens: capacity,
	}
}
```

1. 基本思路就是创建桶时，设置桶的总容量，并设置每隔多久时间投入多少令牌

先看take方法, 看令牌的获取逻辑

```go
// take is the internal version of Take - it takes the current time as
// an argument to enable easy testing.
func (tb *Bucket) take(now time.Time, count int64, maxWait time.Duration) (time.Duration, bool) {
	if count <= 0 {
		return 0, true
	}

	tick := tb.currentTick(now)
	tb.adjustavailableTokens(tick)
	avail := tb.availableTokens - count
	if avail >= 0 {
		tb.availableTokens = avail
		return 0, true
	}
	// Round up the missing tokens to the nearest multiple
	// of quantum - the tokens won't be available until
	// that tick.

	// endTick holds the tick when all the requested tokens will
	// become available.
	endTick := tick + (-avail+tb.quantum-1)/tb.quantum
	endTime := tb.startTime.Add(time.Duration(endTick) * tb.fillInterval)
	waitTime := endTime.Sub(now)
	if waitTime > maxWait {
		return 0, false
	}
	tb.availableTokens = avail
	return waitTime, true
}

// currentTick returns the current time tick, measured
// from tb.startTime.
func (tb *Bucket) currentTick(now time.Time) int64 {
	return int64(now.Sub(tb.startTime) / tb.fillInterval)
}

// adjustavailableTokens adjusts the current number of tokens
// available in the bucket at the given time, which must
// be in the future (positive) with respect to tb.latestTick.
func (tb *Bucket) adjustavailableTokens(tick int64) {
	if tb.availableTokens >= tb.capacity {
		return
	}
	tb.availableTokens += (tick - tb.latestTick) * tb.quantum
	if tb.availableTokens > tb.capacity {
		tb.availableTokens = tb.capacity
	}
	tb.latestTick = tick
	return
}
```

1. 当获取的令牌数为0或者负数，直接返回
2. 拿到当前的tick，根据startTime和fillInterval可以简单算出来
3. adjustavailableTokens根据当前的tick，计算出处于这个tick的时候，桶里应该有多少令牌
4. 比如现在处于tick10, lastestTick是tick5，表示距离上个tick已经过去了5个tick了，5 * quantum 得到应该增加多少令牌数了
5. availableTokens等于原先的令牌数加上上一步增加的令牌数，并需要保证不超过capacity
6. 更新lastestTick为当前tick
7. 如果availableTokens大于请求的令牌数，则返回成功
8. 否则计算需要等多少个tick才能生成请求的令牌数，并返回需要等待的时间

> 这里设计得挺巧妙的，仅仅通过数学计算就算出了availableTokens，并不需要设置定时器之类的东西

```go
// Wait takes count tokens from the bucket, waiting until they are
// available.
func (tb *Bucket) Wait(count int64) {
	if d := tb.Take(count); d > 0 {
		tb.clock.Sleep(d)
	}
}
```

1. Wait方法传入请求的令牌数量
2. tb.Take() 会告诉我们需要等待多久时间才能拿到所有的令牌
3. sleep直接睡那么长的时间

```go
// WaitMaxDuration is like Wait except that it will
// only take tokens from the bucket if it needs to wait
// for no greater than maxWait. It reports whether
// any tokens have been removed from the bucket
// If no tokens have been removed, it returns immediately.
func (tb *Bucket) WaitMaxDuration(count int64, maxWait time.Duration) bool {
	d, ok := tb.TakeMaxDuration(count, maxWait)
	if d > 0 {
		tb.clock.Sleep(d)
	}
	return ok
}
```

```go
const infinityDuration time.Duration = 0x7fffffffffffffff

// Take takes count tokens from the bucket without blocking. It returns
// the time that the caller should wait until the tokens are actually
// available.
//
// Note that if the request is irrevocable - there is no way to return
// tokens to the bucket once this method commits us to taking them.
func (tb *Bucket) Take(count int64) time.Duration {
	tb.mu.Lock()
	defer tb.mu.Unlock()
	d, _ := tb.take(tb.clock.Now(), count, infinityDuration)
	return d
}
```

```go
// TakeMaxDuration is like Take, except that
// it will only take tokens from the bucket if the wait
// time for the tokens is no greater than maxWait.
//
// If it would take longer than maxWait for the tokens
// to become available, it does nothing and reports false,
// otherwise it returns the time that the caller should
// wait until the tokens are actually available, and reports
// true.
func (tb *Bucket) TakeMaxDuration(count int64, maxWait time.Duration) (time.Duration, bool) {
	tb.mu.Lock()
	defer tb.mu.Unlock()
	return tb.take(tb.clock.Now(), count, maxWait)
}

// TakeAvailable takes up to count immediately available tokens from the
// bucket. It returns the number of tokens removed, or zero if there are
// no available tokens. It does not block.
func (tb *Bucket) TakeAvailable(count int64) int64 {
	tb.mu.Lock()
	defer tb.mu.Unlock()
	return tb.takeAvailable(tb.clock.Now(), count)
}

// takeAvailable is the internal version of TakeAvailable - it takes the
// current time as an argument to enable easy testing.
func (tb *Bucket) takeAvailable(now time.Time, count int64) int64 {
	if count <= 0 {
		return 0
	}
	tb.adjustavailableTokens(tb.currentTick(now))
	if tb.availableTokens <= 0 {
		return 0
	}
	if count > tb.availableTokens {
		count = tb.availableTokens
	}
	tb.availableTokens -= count
	return count
}

// Available returns the number of available tokens. It will be negative
// when there are consumers waiting for tokens. Note that if this
// returns greater than zero, it does not guarantee that calls that take
// tokens from the buffer will succeed, as the number of available
// tokens could have changed in the meantime. This method is intended
// primarily for metrics reporting and debugging.
func (tb *Bucket) Available() int64 {
	return tb.available(tb.clock.Now())
}

// available is the internal version of available - it takes the current time as
// an argument to enable easy testing.
func (tb *Bucket) available(now time.Time) int64 {
	tb.mu.Lock()
	defer tb.mu.Unlock()
	tb.adjustavailableTokens(tb.currentTick(now))
	return tb.availableTokens
}

// Capacity returns the capacity that the bucket was created with.
func (tb *Bucket) Capacity() int64 {
	return tb.capacity
}

// Rate returns the fill rate of the bucket, in tokens per second.
func (tb *Bucket) Rate() float64 {
	return 1e9 * float64(tb.quantum) / float64(tb.fillInterval)
}

// Clock represents the passage of time in a way that
// can be faked out for tests.
type Clock interface {
	// Now returns the current time.
	Now() time.Time
	// Sleep sleeps for at least the given duration.
	Sleep(d time.Duration)
}

// realClock implements Clock in terms of standard time functions.
type realClock struct{}

// Now implements Clock.Now by calling time.Now.
func (realClock) Now() time.Time {
	return time.Now()
}

// Now implements Clock.Sleep by calling time.Sleep.
func (realClock) Sleep(d time.Duration) {
	time.Sleep(d)
}
```

其余的方法很简单

