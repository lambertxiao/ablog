---
author: "Lambert Xiao"
title: "LevelDB是干嘛的"
date: "2022-03-25"
summary: "level，多层级"
tags: ["kv存储"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

- KV数据库
- 数据持久化于磁盘上
- 底层基于LSM Tree理论

## 基本使用

> 以 `https://github.com/syndtr/goleveldb` 举例

### 打开db

```go
db, err := leveldb.OpenFile("path/to/db", nil)
...
defer db.Close()
```

### 读写操作

```go
// Remember that the contents of the returned slice should not be modified.
data, err := db.Get([]byte("key"), nil)
...
err = db.Put([]byte("key"), []byte("value"), nil)
...
err = db.Delete([]byte("key"), nil)
```

### 迭代操作

普通迭代

```go
iter := db.NewIterator(nil, nil)
for iter.Next() {
	// Remember that the contents of the returned slice should not be modified, and
	// only valid until the next call to Next.
	key := iter.Key()
	value := iter.Value()
	...
}
iter.Release()
err = iter.Error()
...
```

seek到某个key之后迭代

```go
iter := db.NewIterator(nil, nil)
for ok := iter.Seek(key); ok; ok = iter.Next() {
	// Use key/value.
	...
}
iter.Release()
err = iter.Error()
...
```

条件查找迭代

```go
iter := db.NewIterator(&util.Range{Start: []byte("foo"), Limit: []byte("xoo")}, nil)
for iter.Next() {
	// Use key/value.
	...
}
iter.Release()
err = iter.Error()
```

### 批量写入

```go
batch := new(leveldb.Batch)
batch.Put([]byte("foo"), []byte("value"))
batch.Put([]byte("bar"), []byte("another value"))
batch.Delete([]byte("baz"))
err = db.Write(batch, nil)
...
```

### 使用布隆过滤器

```go
o := &opt.Options{
	Filter: filter.NewBloomFilter(10),
}
db, err := leveldb.OpenFile("path/to/db", o)
...
defer db.Close()
...
```


goleveldb源码分析

## 主要流程分析

### 当Put一个Key时发生了什么

```go
func (db *DB) Put(key, value []byte, wo *opt.WriteOptions) error {
	return db.putRec(keyTypeVal, key, value, wo)
}


func (db *DB) putRec(kt keyType, key, value []byte, wo *opt.WriteOptions) error {
    ...

	merge := !wo.GetNoWriteMerge() && !db.s.o.GetNoWriteMerge()
	sync := wo.GetSync() && !db.s.o.GetNoSync()

	// Acquire write lock.
	if merge {
		select {
		case db.writeMergeC <- writeMerge{sync: sync, keyType: kt, key: key, value: value}:
			if <-db.writeMergedC {
				// Write is merged.
				return <-db.writeAckC
			}
			// Write is not merged, the write lock is handed to us. Continue.
		case db.writeLockC <- struct{}{}:
			// Write lock acquired.
		case err := <-db.compPerErrC:
			// Compaction error.
			return err
		case <-db.closeC:
			// Closed
			return ErrClosed
		}
	} else {
		select {
		case db.writeLockC <- struct{}{}:
			// Write lock acquired.
		case err := <-db.compPerErrC:
			// Compaction error.
			return err
		case <-db.closeC:
			// Closed
			return ErrClosed
		}
	}

	batch := db.batchPool.Get().(*Batch)
	batch.Reset()
	batch.appendRec(kt, key, value)
	return db.writeLocked(batch, batch, merge, sync)
}
```

1. 写之前需要拿到两个bool值，merge和sync，这两个值来源于传入的 `writeOption.NoWriteMerge` 和`db.session.cacheOption.NoSync`
2. 如果需要merge，通过 `writeMergeC` 发起一个合并写请求，并阻塞在 `writeMergedC` 等待合并完成，
同时如果收到合并成功的请求，需要往 `writeAckC` 取出一个ack(以上chan都是在openDB时初始化好的无缓冲chan)

    ```go
    func openDB(s *session) (*DB, error) {
        ...
        db := &DB{
            // Write
            batchPool:    sync.Pool{New: newBatch},
            writeMergeC:  make(chan writeMerge),
            writeMergedC: make(chan bool),
            writeLockC:   make(chan struct{}, 1),
            writeAckC:    make(chan error),
            // Compaction
            tcompCmdC:   make(chan cCmd),
            tcompPauseC: make(chan chan<- struct{}),
            mcompCmdC:   make(chan cCmd),
            compErrC:    make(chan error),
            compPerErrC: make(chan error),
            compErrSetC: make(chan error),
            // Close
            closeC: make(chan struct{}),
        }
        ...
    }
    ```

3. 如果不需要merge，则将key和value添加到batch中等待批量操作

先来看merge操作，找到writeMergeC的接收端

```go
// ourBatch is batch that we can modify.
func (db *DB) writeLocked(batch, ourBatch *Batch, merge, sync bool) error {
    var (
		overflow bool
		merged   int
		batches  = []*Batch{batch}
	)

	if merge {
		// Merge limit.
		var mergeLimit int
		if batch.internalLen > 128<<10 {
			mergeLimit = (1 << 20) - batch.internalLen
		} else {
			mergeLimit = 128 << 10
		}
		mergeCap := mdbFree - batch.internalLen
		if mergeLimit > mergeCap {
			mergeLimit = mergeCap
		}
	...
	merge:
        // 相当于等mergeLimit个请求到了之后才会退出merge循环
		for mergeLimit > 0 {
			select {
			case incoming := <-db.writeMergeC:
				if incoming.batch != nil {
					// Merge batch.
					if incoming.batch.internalLen > mergeLimit {
						overflow = true
						break merge
					}
					batches = append(batches, incoming.batch)
					mergeLimit -= incoming.batch.internalLen
				} else {
					// Merge put.
					internalLen := len(incoming.key) + len(incoming.value) + 8
					if internalLen > mergeLimit {
						overflow = true
						break merge
					}
					if ourBatch == nil {
						ourBatch = db.batchPool.Get().(*Batch)
						ourBatch.Reset()
						batches = append(batches, ourBatch)
					}
					// We can use same batch since concurrent write doesn't
					// guarantee write order.
					ourBatch.appendRec(incoming.keyType, incoming.key, incoming.value)
					mergeLimit -= internalLen
				}
				sync = sync || incoming.sync
				merged++
				db.writeMergedC <- true

			default:
				break merge
			}
		}
	}
	// Release ourBatch if any.
	if ourBatch != nil {
		defer db.batchPool.Put(ourBatch)
	}

	// Seq number.
	seq := db.seq + 1

	// Write journal.
	if err := db.writeJournal(batches, seq, sync); err != nil {
		db.unlockWrite(overflow, merged, err)
		return err
	}

	// Put batches.
	for _, batch := range batches {
		if err := batch.putMem(seq, mdb.DB); err != nil {
			panic(err)
		}
		seq += uint64(batch.Len())
	}

	// Incr seq number.
	db.addSeq(uint64(batchesLen(batches)))

	// Rotate memdb if it's reach the threshold.
	if batch.internalLen >= mdbFree {
		db.rotateMem(0, false)
	}

	db.unlockWrite(overflow, merged, nil)
	return nil
}
```

1. 每次的mergeLimit通过计算得到
2. 当收到一个merge请求时，如果该请求所属的batch已经满了，则跳出merge循环，否则则一只等到mergeLimit减少到0
3. 更新前会提前写日志writeJournal, writeJournal会同时写入一批batch，这一批batch用同一个序列号


## 主要结构

### Journal

### Memdb

### Comparer
### storage


```go
// Storage is the storage. A storage instance must be safe for concurrent use.
type Storage interface {
	// Lock locks the storage. Any subsequent attempt to call Lock will fail
	// until the last lock released.
	// Caller should call Unlock method after use.
	Lock() (Locker, error)

	// Log logs a string. This is used for logging.
	// An implementation may write to a file, stdout or simply do nothing.
	Log(str string)

	// SetMeta store 'file descriptor' that can later be acquired using GetMeta
	// method. The 'file descriptor' should point to a valid file.
	// SetMeta should be implemented in such way that changes should happen
	// atomically.
	SetMeta(fd FileDesc) error

	// GetMeta returns 'file descriptor' stored in meta. The 'file descriptor'
	// can be updated using SetMeta method.
	// Returns os.ErrNotExist if meta doesn't store any 'file descriptor', or
	// 'file descriptor' point to nonexistent file.
	GetMeta() (FileDesc, error)

	// List returns file descriptors that match the given file types.
	// The file types may be OR'ed together.
	List(ft FileType) ([]FileDesc, error)

	// Open opens file with the given 'file descriptor' read-only.
	// Returns os.ErrNotExist error if the file does not exist.
	// Returns ErrClosed if the underlying storage is closed.
	Open(fd FileDesc) (Reader, error)

	// Create creates file with the given 'file descriptor', truncate if already
	// exist and opens write-only.
	// Returns ErrClosed if the underlying storage is closed.
	Create(fd FileDesc) (Writer, error)

	// Remove removes file with the given 'file descriptor'.
	// Returns ErrClosed if the underlying storage is closed.
	Remove(fd FileDesc) error

	// Rename renames file from oldfd to newfd.
	// Returns ErrClosed if the underlying storage is closed.
	Rename(oldfd, newfd FileDesc) error

	// Close closes the storage.
	// It is valid to call Close multiple times. Other methods should not be
	// called after the storage has been closed.
	Close() error
}
```

1. storage层用来对db进行创建、删除、打开等操作
2. storage层具备获取db元信息的能力
3. 总而言之，storage层用来管理db

### session

```go

// session represent a persistent database session.
type session struct {
	// Need 64-bit alignment.
	stNextFileNum    int64 // current unused file number
	stJournalNum     int64 // current journal file number; need external synchronization
	stPrevJournalNum int64 // prev journal file number; no longer used; for compatibility with older version of leveldb
	stTempFileNum    int64
	stSeqNum         uint64 // last mem compacted seq; need external synchronization

	stor     *iStorage
	storLock storage.Locker
	o        *cachedOptions
	icmp     *iComparer
	tops     *tOps

	manifest       *journal.Writer
	manifestWriter storage.Writer
	manifestFd     storage.FileDesc

	stCompPtrs  []internalKey // compaction pointers; need external synchronization
	stVersion   *version      // current version
	ntVersionId int64         // next version id to assign
	refCh       chan *vTask
	relCh       chan *vTask
	deltaCh     chan *vDelta
	abandon     chan int64
	closeC      chan struct{}
	closeW      sync.WaitGroup
	vmu         sync.Mutex

	// Testing fields
	fileRefCh chan chan map[int64]int // channel used to pass current reference stat
}
```

1. session代表同db的一次会话
2. 什么是alignment
3. 什么是jounarl
4. 序列号？
5. iComparer
6. FileDesc
7. internalKey
8. vTask
9. vDelta
10. tOps

```go
// Creates new initialized session instance.
func newSession(stor storage.Storage, o *opt.Options) (s *session, err error) {
	if stor == nil {
		return nil, os.ErrInvalid
	}
	storLock, err := stor.Lock()
	if err != nil {
		return
	}
	s = &session{
		stor:      newIStorage(stor),
		storLock:  storLock,
		refCh:     make(chan *vTask),
		relCh:     make(chan *vTask),
		deltaCh:   make(chan *vDelta),
		abandon:   make(chan int64),
		fileRefCh: make(chan chan map[int64]int),
		closeC:    make(chan struct{}),
	}
	s.setOptions(o)
	s.tops = newTableOps(s)

	s.closeW.Add(1)
	go s.refLoop()
	s.setVersion(nil, newVersion(s))
	s.log("log@legend F·NumFile S·FileSize N·Entry C·BadEntry B·BadBlock Ke·KeyError D·DroppedEntry L·Level Q·SeqNum T·TimeElapsed")
	return
}
```

1. 每次创建一个会话，会锁住stroage
2. 什么时候解锁？这意味着leveldb不支持多个session并发咯？

### tOps

1. tOps包含了所有对table的操作
2. cache是files cache
3. bcache是block cache, bpool是为bcache服务的

```go
// Table operations.
type tOps struct {
	s            *session
	noSync       bool
	evictRemoved bool
	cache        *cache.Cache
	bcache       *cache.Cache
	bpool        *util.BufferPool
}
```

### FileDesc

FileDesc起到一个文件描述符的作用

```go
type FileDesc struct {
	Type FileType
	Num  int64
}

// FileType represent a file type.
type FileType int

// File types.
const (
	TypeManifest FileType = 1 << iota
	TypeJournal
	TypeTable
	TypeTemp

	TypeAll = TypeManifest | TypeJournal | TypeTable | TypeTemp
)
```

1. Type总共有4种类型
2. Num是文件号，session里的stNextFileNum维护了当前会话里下一个被分配出去文件号

### Cacher

1. Cacher从接口上看显然是对Node的操作
2. Node是干什么的

```go
// Cacher provides interface to implements a caching functionality.
// An implementation must be safe for concurrent use.
type Cacher interface {
	// Capacity returns cache capacity.
	Capacity() int

	// SetCapacity sets cache capacity.
	SetCapacity(capacity int)

	// Promote promotes the 'cache node'.
	Promote(n *Node)

	// Ban evicts the 'cache node' and prevent subsequent 'promote'.
	Ban(n *Node)

	// Evict evicts the 'cache node'.
	Evict(n *Node)

	// EvictNS evicts 'cache node' with the given namespace.
	EvictNS(ns uint64)

	// EvictAll evicts all 'cache node'.
	EvictAll()

	// Close closes the 'cache tree'
	Close() error
}

// Node is a 'cache node'.
type Node struct {
	r *Cache

	hash    uint32
	ns, key uint64

	mu    sync.Mutex
	size  int
	value Value

	ref   int32
	onDel []func()

	CacheData unsafe.Pointer
}
```

### Cache

1. cache用来存放Cacher所持有的nodes数量
2. 带有读写锁

```go
// Cache is a 'cache map'.
type Cache struct {
	mu     sync.RWMutex
	mHead  unsafe.Pointer // *mNode
	nodes  int32
	size   int32
	cacher Cacher
	closed bool
}
```

### BufferPool

1. BufferPool显然是一个缓冲池，结合pool的类型为[]sync.Pool，大概率是用来池化对象的。
2. 6个uint32的属性是干嘛的？

```go
// BufferPool is a 'buffer pool'.
type BufferPool struct {
	pool     [6]sync.Pool
	baseline [5]int

	get     uint32
	put     uint32
	less    uint32
	equal   uint32
	greater uint32
	miss    uint32
}
```

### vTask

vTask即version task，用来引用或发布以一个版本任务

```go
// vTask defines a version task for either reference or release.
type vTask struct {
	vid     int64
	files   []tFiles
	created time.Time
}
```

### vDelta

vDelta即version delta, 表示下一个版本和当前指定版本之间的变化信息

```go
// vDelta indicates the change information between the next version
// and the currently specified version
type vDelta struct {
	vid     int64
	added   []int64
	deleted []int64
}
```

### session.refLoop

1. fileRef 表文件引用计数器

```go
func (s *session) refLoop() {
	var (
		fileRef    = make(map[int64]int)    // Table file reference counter
		ref        = make(map[int64]*vTask) // Current referencing version store
		deltas     = make(map[int64]*vDelta)
		referenced = make(map[int64]struct{})
		released   = make(map[int64]*vDelta)  // Released version that waiting for processing
		abandoned  = make(map[int64]struct{}) // Abandoned version id
		next, last int64
	)
	// addFileRef adds file reference counter with specified file number and
	// reference value
	addFileRef := func(fnum int64, ref int) int {
		ref += fileRef[fnum]
		if ref > 0 {
			fileRef[fnum] = ref
		} else if ref == 0 {
			delete(fileRef, fnum)
		} else {
			panic(fmt.Sprintf("negative ref: %v", fnum))
		}
		return ref
	}
	// skipAbandoned skips useless abandoned version id.
	skipAbandoned := func() bool {
		if _, exist := abandoned[next]; exist {
			delete(abandoned, next)
			return true
		}
		return false
	}
	// applyDelta applies version change to current file reference.
	applyDelta := func(d *vDelta) {
		for _, t := range d.added {
			addFileRef(t, 1)
		}
		for _, t := range d.deleted {
			if addFileRef(t, -1) == 0 {
				s.tops.remove(storage.FileDesc{Type: storage.TypeTable, Num: t})
			}
		}
	}

	timer := time.NewTimer(0)
	<-timer.C // discard the initial tick
	defer timer.Stop()

	// processTasks processes version tasks in strict order.
	//
	// If we want to use delta to reduce the cost of file references and dereferences,
	// we must strictly follow the id of the version, otherwise some files that are
	// being referenced will be deleted.
	//
	// In addition, some db operations (such as iterators) may cause a version to be
	// referenced for a long time. In order to prevent such operations from blocking
	// the entire processing queue, we will properly convert some of the version tasks
	// into full file references and releases.
	processTasks := func() {
		timer.Reset(maxCachedTime)
		// Make sure we don't cache too many version tasks.
		for {
			// Skip any abandoned version number to prevent blocking processing.
			if skipAbandoned() {
				next += 1
				continue
			}
			// Don't bother the version that has been released.
			if _, exist := released[next]; exist {
				break
			}
			// Ensure the specified version has been referenced.
			if _, exist := ref[next]; !exist {
				break
			}
			if last-next < maxCachedNumber && time.Since(ref[next].created) < maxCachedTime {
				break
			}
			// Convert version task into full file references and releases mode.
			// Reference version(i+1) first and wait version(i) to release.
			// FileRef(i+1) = FileRef(i) + Delta(i)
			for _, tt := range ref[next].files {
				for _, t := range tt {
					addFileRef(t.fd.Num, 1)
				}
			}
			// Note, if some compactions take a long time, even more than 5 minutes,
			// we may miss the corresponding delta information here.
			// Fortunately it will not affect the correctness of the file reference,
			// and we can apply the delta once we receive it.
			if d := deltas[next]; d != nil {
				applyDelta(d)
			}
			referenced[next] = struct{}{}
			delete(ref, next)
			delete(deltas, next)
			next += 1
		}

		// Use delta information to process all released versions.
		for {
			if skipAbandoned() {
				next += 1
				continue
			}
			if d, exist := released[next]; exist {
				if d != nil {
					applyDelta(d)
				}
				delete(released, next)
				next += 1
				continue
			}
			return
		}
	}

	for {
		processTasks()

		select {
		case t := <-s.refCh:
			if _, exist := ref[t.vid]; exist {
				panic("duplicate reference request")
			}
			ref[t.vid] = t
			if t.vid > last {
				last = t.vid
			}

		case d := <-s.deltaCh:
			if _, exist := ref[d.vid]; !exist {
				if _, exist2 := referenced[d.vid]; !exist2 {
					panic("invalid release request")
				}
				// The reference opt is already expired, apply
				// delta here.
				applyDelta(d)
				continue
			}
			deltas[d.vid] = d

		case t := <-s.relCh:
			if _, exist := referenced[t.vid]; exist {
				for _, tt := range t.files {
					for _, t := range tt {
						if addFileRef(t.fd.Num, -1) == 0 {
							s.tops.remove(t.fd)
						}
					}
				}
				delete(referenced, t.vid)
				continue
			}
			if _, exist := ref[t.vid]; !exist {
				panic("invalid release request")
			}
			released[t.vid] = deltas[t.vid]
			delete(deltas, t.vid)
			delete(ref, t.vid)

		case id := <-s.abandon:
			if id >= next {
				abandoned[id] = struct{}{}
			}

		case <-timer.C:

		case r := <-s.fileRefCh:
			ref := make(map[int64]int)
			for f, c := range fileRef {
				ref[f] = c
			}
			r <- ref

		case <-s.closeC:
			s.closeW.Done()
			return
		}
	}
}
```