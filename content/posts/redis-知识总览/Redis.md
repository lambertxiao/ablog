---
author: "Lambert Xiao"
title: "Redis"
date: "2022-03-06"
summary: "单线程、全内存、AOF、RDB、单点、哨兵、集群"
tags: ["redis"]
categories: ["redis"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# Redis

## 常用数据结构

- strings

- set

- sorted set

- hash（哈希表）

- list（双向链表）

## 缓存一致性问题

## 什么是雪崩

同一时刻大量的缓存失效

## 什么是缓存穿透

缓存和数据库里都没有数据，使用布隆过滤器，在接口处校验非法请求

## 什么是缓存击穿

大量的请求同时在一个key上，当这个key失效时，大量请求直接落到数据库；热点数据永不过期

## Redis为什么快

1. 单线程：减少线程间切换的开销，不用去考虑各种锁的问题，不存在加锁释放锁操作

2. 完全基于内存的，绝大部份请求都是基于内存的操作

## Redis的淘汰策略

- no-evicition：不淘汰，直接报错
- allkeys-random：随机淘汰
- allkeys-lru：最近最少使用的淘汰
- volatile-random：已设置ttl的key随机淘汰
- volatile-lru：已设置ttl的key最近最少使用的淘汰
- volatile-ttl：快过期的优先淘汰

## Redis的持久化策略

- RDB

    定期将内存中的数据保存到一个 dump 的文件中，fork子进程，定期写临时文件，临时文件写完直接替换原来的文件

- AOF

    把所有的对 Redis 的服务器进行修改的命令都存到一个文件里，命令的集合；
    每一个写命令都通过 write 函数追加到 appendonly.aof，同步策略：按秒，按写请求，数据量大，并有性能影响

## Redis的单点故障问题

主从模式：主节点写，从节点读

哨兵模式
