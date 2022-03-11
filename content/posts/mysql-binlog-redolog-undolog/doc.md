---
author: "Lambert Xiao"
title: "MySQL的三种日志-binlog、redolog、undolog"
date: "2022-03-11"
summary: "名字相近，其实长得不一样"
tags: ["mysql"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 总览

![](../mysql更新流程.png)

## binlog

bin log称为归档日志、二进制日志，属于MySQL Server层面的，用于记录数据库表结构和表数据的变更，可以简单理解为存储每条变更的sql语句，比如insert、delete、update（当然，不仅是sql，还有事务id，执行时间等等）。

### 产生时机

事务提交的时候，一次性将事务中的sql语句按照一定格式记录到binlog

### 有什么用

主要有两个作用：主从复制和恢复数据。目前大部分数据库架构都是一主多从，从服务器通过访问主服务器的binlog，保证数据一致性。binlog记录数据库的变更，可以通过它恢复数据

### 什么时候落盘

取决于sync_binlog参数

- 0：事务提交后，由操作系统决定什么时候把缓存刷新到磁盘（性能最好，安全性最差）
- 1：每提交一次事务，调用一次fsync将缓存写入到磁盘（安全性最好，性能最差）
- n：当提交n次事务后，调用一次fsync将缓存写入到磁盘

### 文件记录模式

bin log有三种文件记录模式，分别是row、statement、mixed

- row（row-based replication，PBR）

    记录每一行数据的修改情况
    优点：能够清楚记录每行数据修改细节，能够完全保证主从数据一致性
    缺点：批量操作时会产生大量的日志，比如alter table

- statement

    记录每条修改数据的sql，可认为sql语句复制
    优点：日志数据量小，减少磁盘IO，提高存储和恢复速度
    缺点：在某些情况下会出现主从不一致，比如sql语句中包含**now()**等函数

- mixed
    上面两种模式的混合，MySQL会根据sql语句选择写入模式，一般使用statement模式保存bin log，对于statement模式无法复制的操作，使用row模式保存bin log。

## redo-log

redolog称为重做日志，属于InnoDB存储引擎层的日志，记录物理页的修改信息，而不是某一行或几行修改成什么样。redo-log本质上是WAL

### 什么时候产生

事务开始，就会写入redolog。redolog写入到磁盘并不是随着事务提交才写入，而是在事务执行过程中，就已经写入到磁盘

### 有什么用

可用于恢复数据。redolog是在事务开始后就写入到磁盘，且是顺序IO，写入速度较快。如果服务器突然掉电，InnoDB引擎会使用redolog把数据库恢复到掉电前的时刻，保证数据的完整性

### 什么时候落盘

InnoDB先把日志写到缓冲区（log buffer），然后再把日志从log buffer刷到os buffer，最后调用文件系统的fsync函数将日志刷新到磁盘。重做日志写入时机由参数innodb_flush_log_at_trx_commit决定

- 0：每秒一次，把log buffer写入os buffer，并调用fsync刷到磁盘
- 1：每次提交事务时，把log buffer写入os buffer，并调用fsync刷到磁盘
- 2：每次提交事务时，只是写入到os buffer，然后每秒一次调用fsync将日志刷新到磁盘

一般取值为2，因为即使MySQL宕机，数据也没有丢失。只有整个服务器挂了，才损失1秒的数据

### 原理

redolog包含了两部分内容，一是redo log buffer, 二是redo logfile。

其中redo log buffer本质上是一个固定大小的环形的缓冲区，在redo log日志中设置了两个标志位置，checkpoint和write_pos，分别表示记录擦除的位置和记录写入的位置。

![](../redolog.png)

当write_pos标志到了日志结尾时，会从结尾跳至日志头部进行重新循环写入。所以redo log的逻辑结构并不是线性的，而是可看作一个圆周运动。write_pos与checkpoint中间的空间可用于写入新数据，写入和擦除都是往后推移，循环往复的。当write_pos追上checkpoint时，表示redo log日志已经写满。这时不能继续执行新的数据库更新语句，需要停下来先删除一些记录，执行checkpoint规则腾出可写空间。

## undo-log

undo log称为回滚日志，属于InnoDB存储引擎层，是逻辑日志，记录每行数据。当我们变更数据时，就会产生undo log，可以认为insert一条数据，undo log会记录一条对应的delete日志，反之亦然。

### 什么时候产生

在事务开始前，将当前版本生成undo log

### 有什么用

主要作用：提供回滚和多版本并发控制（MVCC）

- 回滚：当需要rollback时，从undo log的逻辑记录读取相应的内容进行回滚
- MVCC：undo log记录中存储的是旧版本数据，当一个事务需要读取数据时，会顺着undo链找到满足其可见性的记录

### 原理

![](../undolog.png)
