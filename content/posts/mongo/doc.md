---
author: "Lambert Xiao"
title: "MongoDB"
date: "2022-05-06"
summary: ""
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 分片模式下数据分发流程

![](../1.png)

1. mongos在启动后，其内部会维护一份路由表缓存并通过心跳机制与Contg Server （配置中心） 保持同步
2. 业务请求进入后，由mongos开始接管
3. mongos检索本地路由表，根据请求中的分片键信息找到相应的chunk，进一步确定所在的分片。
4. mongos向目标分片发起操作，并返回最终结果

## 避免广播操作

需要向所有的分片查询结果

![](../2.png)

单分片故障会影响整个查询

![](../3.png)

## 保证索引唯一性

分片模式会影响索引的唯一性。由于没有手段保证多个分片上的数据唯一，所以唯一性索引必须与分片键使用相同的字段，或者以分片键作为前级。

如下面的选择可以避免冲突。

(1） 唯一性索引为：{a：1}，分片键采用a字段。

(2） 唯一性索引为：{a：1，b：1}, 分片键采用a字段。

## 分片均衡

### 手动均衡

### 自动均衡

![](../4.png)