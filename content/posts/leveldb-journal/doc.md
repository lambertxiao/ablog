---
author: "Lambert Xiao"
title: "leveldb内部实现之journal"
date: "2022-03-31"
summary: "了解一下leveldb的WAL是怎么做的"
tags: ["leveldb"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover: 
  image: "/cover/leveldb内部实现之memdb.png"
---


journal是levedb中的write ahead log，由于leveldb是将数据先写入内存中再同步到磁盘的，为了防止db异常退出导致内存丢数据，leveldb每次在写入key之前，会利用顺序写文件的方式记录journal。
因此一个journal会记录下一次写入操作的数据。

> 以下代码分析基于go版本的leveldb `https://github.com/syndtr/goleveldb`

## 什么时候会触发写journal

Put写入数据时，最终会走到的writeLocked方法里的以下代码块

```go
// ourBatch is batch that we can modify.
func (db *DB) writeLocked(batch, ourBatch *Batch, merge, sync bool) error {
	...

	// Seq number.
	seq := db.seq + 1

    // 在这先写日志
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

	...
	return nil
}
```


### journal的结构

先分析下journal的实现，在DB结构体中，journal的类型为 `*journal.Writer`


```go
type DB struct {
    ...
	journal         *journal.Writer
	// journalWriter   storage.Writer
	// journalFd       storage.FileDesc
	...
}

// Writer writes journals to an underlying io.Writer.
type Writer struct {
	// w is the underlying writer.
	w io.Writer
	// seq is the sequence number of the current journal.
	seq int
	// f is w as a flusher.
	f flusher
	// buf[i:j] is the bytes that will become the current chunk.
	// The low bound, i, includes the chunk header.
	i, j int
	// buf[:written] has already been written to w.
	// written is zero unless Flush has been called.
	written int
	// first is whether the current chunk is the first chunk of the journal.
	first bool
	// pending is whether a chunk is buffered but not yet written.
	pending bool
	// err is any accumulated error.
	err error
	// buf is the buffer.
	buf [blockSize]byte
}
```

1. 成员变量w实际上会在打开DB时被传入一个文件，见以下代码，可以看出写入的journal文件实际是 `${dbpath}/%06d.log`

    ```go

    func (fs *fileStorage) Create(fd FileDesc) (Writer, error) {
        ...
        of, err := os.OpenFile(filepath.Join(fs.path, fsGenName(fd)), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
        if err != nil {
            return nil, err
        }
        fs.open++
        return &fileWrap{File: of, fs: fs, fd: fd}, nil
    }

    func fsGenName(fd FileDesc) string {
        switch fd.Type {
        case TypeManifest:
            return fmt.Sprintf("MANIFEST-%06d", fd.Num)
        case TypeJournal:
            return fmt.Sprintf("%06d.log", fd.Num)
        case TypeTable:
            return fmt.Sprintf("%06d.ldb", fd.Num)
        case TypeTemp:
            return fmt.Sprintf("%06d.tmp", fd.Num)
        default:
            panic("invalid file type")
        }
    }

    func OpenFile(path string, readOnly bool) (Storage, error) {
        ...

        fs := &fileStorage{
            path:     path,
            readOnly: readOnly,
            flock:    flock,
            logw:     logw,
            logSize:  logSize,
        }
        ...
    }
    ```

2. 每个journal都有一个序列号seq
3. buf存放着journal的数据
4. 一个journal可以拆分为多个chunk, i和j标记当前写入的chunk的左右边界
5. first标记当前写入的chunk是否是第一个chunk
6. pending表示当前的chunk是否还没被写入磁盘


## journal的写入

writeJournal的实现

```go
func (db *DB) writeJournal(batches []*Batch, seq uint64, sync bool) error {
    // 拿到本次负责写入的writer
	wr, err := db.journal.Next()
	if err != nil {
		return err
	}

    // 将数据写入writer，此时数据还在内存缓冲区中
	if err := writeBatchesWithHeader(wr, batches, seq); err != nil {
		return err
	}

    // 将journal内的数据刷入磁盘
	if err := db.journal.Flush(); err != nil {
		return err
	}
	if sync {
		return db.journalWriter.Sync()
	}
	return nil
}
```

1. 通过Next拿到一个writer
2. 将batch批量写入writer中

### Next的作用

```go
const (
	blockSize  = 32 * 1024
	headerSize = 7
)

// Next returns a writer for the next journal. The writer returned becomes stale
// after the next Close, Flush or Next call, and should no longer be used.
func (w *Writer) Next() (io.Writer, error) {
	w.seq++
	if w.err != nil {
		return nil, w.err
	}
	if w.pending {
		w.fillHeader(true)
	}
	w.i = w.j
	w.j = w.j + headerSize
	// Check if there is room in the block for the header.
	if w.j > blockSize {
		// Fill in the rest of the block with zeroes.
		for k := w.i; k < blockSize; k++ {
			w.buf[k] = 0
		}
		w.writeBlock()
		if w.err != nil {
			return nil, w.err
		}
	}
	w.first = true
	w.pending = true
	return singleWriter{w, w.seq}, nil
}
```

1. 当next调用的时候，检查journal里上一个写入的chunk是否处于pending状态，如果是，则fillHeader往buf写入该chunk的header信息
2. 更新当前写入chunk的左右边界i，j
3. 如果因为本次写入导致buf里的数据已经大于32KB了，则需要将buf里的数据写入到文件里
4. 由此可见，journal写入block的时机实际上是在每次写入的过程中判断的

```go
const (
	fullChunkType   = 1 // 整个buf里只有一个chunk
	firstChunkType  = 2 // 第一块chunk
	middleChunkType = 3 // 位于中间的chunk
	lastChunkType   = 4 // 最后一块chunk
)

// fillHeader fills in the header for the pending chunk.
func (w *Writer) fillHeader(last bool) {
	if w.i+headerSize > w.j || w.j > blockSize {
		panic("leveldb/journal: bad writer state")
	}
	if last {
		if w.first {
			w.buf[w.i+6] = fullChunkType
		} else {
			w.buf[w.i+6] = lastChunkType
		}
	} else {
		if w.first {
			w.buf[w.i+6] = firstChunkType
		} else {
			w.buf[w.i+6] = middleChunkType
		}
	}
    // 存入crc校验码
	binary.LittleEndian.PutUint32(w.buf[w.i+0:w.i+4], util.NewCRC(w.buf[w.i+6:w.j]).Value())
    // 存入chunk的大小
	binary.LittleEndian.PutUint16(w.buf[w.i+4:w.i+6], uint16(w.j-w.i-headerSize))
}
```

1. chunk有header，header里记录里chunk的类型
2. chunk存放着数据部分的CRC校验码，用于检查数据是否完整
3. chunk里存放这数据大小
4. 对于buf, 索引0-3存放chunk数据的crc，索引4-5存放chunk数据的大小，索引6存放着chunk的类型

```go
// writeBlock writes the buffered block to the underlying writer, and reserves
// space for the next chunk's header.
func (w *Writer) writeBlock() {
	_, w.err = w.w.Write(w.buf[w.written:])
	w.i = 0
	w.j = headerSize
	w.written = 0
}
```

## journal的读取
