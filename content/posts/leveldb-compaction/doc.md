---

author: "Lambert Xiao"
title: "leveldb内部实现之compact"
date: "2022-03-31"
summary: "了解一下leveldb的WAL是怎么做的"
tags: ["leveldb"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## compact的作用

DB有一个后台线程负责将memtable持久化成sstable，以及均衡整个DB各个level层的sstable。compact分为minor compaction和major compaction。memtable持久化成sstable称为minor compaction，level(n)和level(n+1)之间某些sstable的merge称为major compaction。

## compact的时机

## compact的种类

### Major Compaction

指的是 immutable memtable持久化为 sst 文件

主要流程：

1. 将内存中的memsstable格式化成sst文件的格式；

2. 选择这个新sst文件放置的level，规则如图 2 所示（来自文献 [2]）；

3. 将新sst文件放置到第2步选出的level中。

### Major Compaction

指的是 sst 文件之间的 compaction

主要分为：

1. Manual Compaction，是人工触发的Compaction，由外部接口调用产生
2. Size Compaction，是根据每个level的总文件大小来触发

    第1步：计算的score值，可以得出 max score，从而得出了应该哪一个 level 上进行 Compact，

    第2步：假设上面选出的是 level n，那么第 2 步就是选择出需要 Compact 的文件，其包含两步，首先在 level n 中选出需要 Compact 的文件文件（对应第2.1步）；然后根据level n选出的文件的key的begin和end来选出 level n+1 层的 sst 文件（对应第2.2步）：

    ​ 第2.1步：确定level n参与Compact的文件列表

    ​ 2.1.1: 将begin key更新为level n 上次Compact操作的文件的largest key。然后顺序查找level的sst文件，返回第一个largest key > begin key的sst文件，并加入到level n需要Compact的文件列表中；

    2.1.2: 如果是n==0，把sst文件都检查一遍，如果存在重叠则加入Compact文件列表中。因为level 0中，所有的文件之间都有可能存在重叠（overlap）。

    ​ 第2.2步：确定level n+1参与Compact的文件列表；

    ​ 2.2.1: 计算出level n参与Compact的文件列表的所有sst文件的总和key范围的begin和end；

    ​ 2.2.2: 根据2.2.1计算出来的begin和end，去获取根level n+1有重叠（overlap）的sst文件列表；

    ​ 2.2.3: 计算当前的level n 和 n+1参与Compact的两个文件列表的总和，如果小于阈值kExpandedCompactionByteSizeLimit=50M，那么会继续尝试在level n中选择出合适的sst文件，考虑到不影响理解，具体细节暂时省略。

3. Seek Compaction，每个文件的 seek miss 次数都有一个阈值，如果超过了这个阈值，那么认为这个文件需要Compact

    在levelDB中，每一个新的sst文件，都有一个 allowed_seek 的初始阈值，表示最多容忍 seek miss 多少次，每个调用 Get seek miss 的时候，就会执行减1（allowed_seek--）。其中 allowed_seek 的初始阈值的计算方式为：

    allowed_seeks = (sst文件的file size / 16384);  // 16348——16kb
        if ( allowed_seeks < 100 ) 
            allowed_seeks = 100;
    LevelDB认为如果一个 sst 文件在 level i 中总是没总到，而是在 level i+1 中找到，那么当这种 seek miss 积累到一定次数之后，就考虑将其从 level i 中合并到 level i+1 中，这样可以避免不必要的 seek miss 消耗 read I/O。当然在引入布隆过滤器后，这种查找消耗的 IO 就会变小很多。

    执行条件
    当 allowed_seeks 递减到小于0了，那么将标记为需要Compact的文件。但是由于Size Compaction的优先级高于Seek Compaction，所以在不存在Size Compaction的时候，且触发了Compaction，那么Seek Compaction就能执行。

    核心过程
    计算 sst 的 allowed_seek 都是在 sst 刚开始新建的时候完成；而每次 Get（key）操作都会更新 allowed_seek，当allowed_seeks 递减到小于0了，那么将标记为需要 Compact 的文件。

## compact的具体实现

```go

func openDB(s *session) (*DB, error) {
	...

	if readOnly {
		db.SetReadOnly()
	} else {
		db.closeW.Add(2)
		go db.tCompaction()
		go db.mCompaction()
		// go db.jWriter()
	}
	...
}
```

1. mCompaction对应着将immutable持久化成sstable
2. tCompaction则是对sstable之间的compact

### mCompaction

```go
func (db *DB) mCompaction() {
	...

	for {
		select {
		case x = <-db.mcompCmdC:
			switch x.(type) {
			case cAuto:
				db.memCompaction()
				x.ack(nil)
				x = nil
			default:
				panic("leveldb: unknown command")
			}
		case <-db.closeC:
			return
		}
	}
}
```

1. mCompaction工作在一个独立的协程中，接收mcompCmdC命令，执行memCompaction操作

#### memCompaction

```go
func (db *DB) memCompaction() {
    // 拿到immutable
	mdb := db.getFrozenMem()
	...

    // 开启一个 "memdb@flush" 事
	// Generate tables.
	db.compactionTransactFunc("memdb@flush", func(cnt *compactionTransactCounter) (err error) {
		stats.startTimer()
        // 在事务中处理memdb
		flushLevel, err = db.s.flushMemdb(rec, mdb.DB, db.memdbMaxLevel)
		stats.stopTimer()
		return
	}, func() error {
		for _, r := range rec.addedTables {
			db.logf("memdb@flush revert @%d", r.num)
			if err := db.s.stor.Remove(storage.FileDesc{Type: storage.TypeTable, Num: r.num}); err != nil {
				return err
			}
		}
		return nil
	})

	...
}
```

#### compactionTransactFunc

```go
func (db *DB) compactionTransactFunc(name string, run func(cnt *compactionTransactCounter) error, revert func() error) {
	db.compactionTransact(name, &compactionTransactFunc{run, revert})
}
```

1. 定义了事务的执行方法run以及事务的恢复方法revert


#### flushMemdb

```go
func (s *session) flushMemdb(rec *sessionRecord, mdb *memdb.DB, maxLevel int) (int, error) {
	// Create sorted table.
	iter := mdb.NewIterator(nil)
	defer iter.Release()
	t, n, err := s.tops.createFrom(iter)
	if err != nil {
		return 0, err
	}

    // 生成的sstable需要被放入哪一层有一套判断方式
	flushLevel := s.pickMemdbLevel(t.imin.ukey(), t.imax.ukey(), maxLevel)
	rec.addTableFile(flushLevel, t)

	s.logf("memdb@flush created L%d@%d N·%d S·%s %q:%q", flushLevel, t.fd.Num, n, shortenb(int(t.size)), t.imin, t.imax)
	return flushLevel, nil
}
```

#### pickMemdbLevel

```go
func (v *version) pickMemdbLevel(umin, umax []byte, maxLevel int) (level int) {
	if maxLevel > 0 {
		if len(v.levels) == 0 {
			return maxLevel
		}
		if !v.levels[0].overlaps(v.s.icmp, umin, umax, true) {
			var overlaps tFiles
			for ; level < maxLevel; level++ {
				if pLevel := level + 1; pLevel >= len(v.levels) {
					return maxLevel
				} else if v.levels[pLevel].overlaps(v.s.icmp, umin, umax, false) {
					break
				}
				if gpLevel := level + 2; gpLevel < len(v.levels) {
					overlaps = v.levels[gpLevel].getOverlaps(overlaps, v.s.icmp, umin, umax, false)
					if overlaps.size() > int64(v.s.o.GetCompactionGPOverlaps(level)) {
						break
					}
				}
			}
		}
	}
	return
}
```

### tCompaction

```go
func (db *DB) tCompaction() {
	var (
		x     cCmd
		waitQ []cCmd
	)

	...

	for {
		...
		if x != nil {
			switch cmd := x.(type) {
			case cAuto:
				if cmd.ackC != nil {
					// Check the write pause state before caching it.
					if db.resumeWrite() {
						x.ack(nil)
					} else {
						waitQ = append(waitQ, x)
					}
				}
			case cRange:
				x.ack(db.tableRangeCompaction(cmd.level, cmd.min, cmd.max))
			default:
				panic("leveldb: unknown command")
			}
			x = nil
		}
		db.tableAutoCompaction()
	}
}
```

#### tableRangeCompaction

```go
func (db *DB) tableRangeCompaction(level int, umin, umax []byte) error {
	db.logf("table@compaction range L%d %q:%q", level, umin, umax)
	if level >= 0 {
		if c := db.s.getCompactionRange(level, umin, umax, true); c != nil {
			db.tableCompaction(c, true)
		}
	} else {
        // 循环直到没有内容需要合并
		// Retry until nothing to compact.
		for {
			compacted := false

			// Scan for maximum level with overlapped tables.
			v := db.s.version()
			m := 1
			for i := m; i < len(v.levels); i++ {
				tables := v.levels[i]
				if tables.overlaps(db.s.icmp, umin, umax, false) {
					m = i
				}
			}
			v.release()

			for level := 0; level < m; level++ {
				if c := db.s.getCompactionRange(level, umin, umax, false); c != nil {
					db.tableCompaction(c, true)
					compacted = true
				}
			}

			if !compacted {
				break
			}
		}
	}

	return nil
}
```

#### tableCompaction

```go
func (db *DB) tableCompaction(c *compaction, noTrivial bool) {
	defer c.release()

	rec := &sessionRecord{}
	rec.addCompPtr(c.sourceLevel, c.imax)

	if !noTrivial && c.trivial() {
		t := c.levels[0][0]
		db.logf("table@move L%d@%d -> L%d", c.sourceLevel, t.fd.Num, c.sourceLevel+1)
		rec.delTable(c.sourceLevel, t.fd.Num)
		rec.addTableFile(c.sourceLevel+1, t)
		db.compactionCommit("table-move", rec)
		return
	}

	var stats [2]cStatStaging
	for i, tables := range c.levels {
		for _, t := range tables {
			stats[i].read += t.size
			// Insert deleted tables into record
			rec.delTable(c.sourceLevel+i, t.fd.Num)
		}
	}
	sourceSize := int(stats[0].read + stats[1].read)
	minSeq := db.minSeq()
	db.logf("table@compaction L%d·%d -> L%d·%d S·%s Q·%d", c.sourceLevel, len(c.levels[0]), c.sourceLevel+1, len(c.levels[1]), shortenb(sourceSize), minSeq)

	b := &tableCompactionBuilder{
		db:        db,
		s:         db.s,
		c:         c,
		rec:       rec,
		stat1:     &stats[1],
		minSeq:    minSeq,
		strict:    db.s.o.GetStrict(opt.StrictCompaction),
		tableSize: db.s.o.GetCompactionTableSize(c.sourceLevel + 1),
	}
	db.compactionTransact("table@build", b)

	// Commit.
	stats[1].startTimer()
	db.compactionCommit("table", rec)
	stats[1].stopTimer()

	resultSize := int(stats[1].write)
	db.logf("table@compaction committed F%s S%s Ke·%d D·%d T·%v", sint(len(rec.addedTables)-len(rec.deletedTables)), sshortenb(resultSize-sourceSize), b.kerrCnt, b.dropCnt, stats[1].duration)

	// Save compaction stats
	for i := range stats {
		db.compStats.addStat(c.sourceLevel+1, &stats[i])
	}
	switch c.typ {
	case level0Compaction:
		atomic.AddUint32(&db.level0Comp, 1)
	case nonLevel0Compaction:
		atomic.AddUint32(&db.nonLevel0Comp, 1)
	case seekCompaction:
		atomic.AddUint32(&db.seekComp, 1)
	}
}
```