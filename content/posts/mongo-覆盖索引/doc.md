---
author: "Lambert Xiao"
title: "MongoDB覆盖索引"
date: "2022-05-07"
summary: "什么是覆盖索引"
tags: ["mongo"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 介绍

首先，覆盖索引并不是一种索引，而是指一种查询优化的行为。

我们知道，在一棵二级索引的B+树上，索引1的值存在于树的叶子节点上。因此，如果我们希望查询的字段被包含在索引中，则直接查找二级索引树就可以获得，而不需要再次通过_id索引查找出原始的文档。

相比“非覆盖式”的查找，覆盖索引1的这种行为可以減少一次对最终文档数据的检索操作（该操作也被称为回表）。

大部分情况下，二级素引树常驻在内存中，覆盖索引式的查询可以保证一次检索行为仅仅发生在内存中，即避免了对磁盘的1/0操作，这对于性能的提升有显著的效果。

简单来说，就是需要查询的字段已经在索引里了，可以优化查询的方式，使mongo不去查源文档，从而减少一次查询

## 怎么用


假设doc结构如下：

```json
{
    "_id" : ObjectId("62764716ecf253c7e26f4af3"),
    "name" : "1",
    "gender" : "male"
}
```

现有索引：

```js
db.user.ensureIndex({name: 1})

```

按下面方式查询时会触发覆盖索引优化：

```js
db.user.find({name: "1"}, {name: 1, _id: 0})
```

`_id: 0` 让_id字段不要随查询返回


使用下面命令确认：

```js
db.user.find({name: "1"}, {name: 1, _id: 0}).explain()
```

```json
/* 1 */
{
    "queryPlanner" : {
        "plannerVersion" : 1,
        "namespace" : "test01.user",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "name" : {
                "$eq" : "1"
            }
        },
        "queryHash" : "3066FB64",
        "planCacheKey" : "A5386A93",
        "winningPlan" : {
            "stage" : "PROJECTION_COVERED",
            "transformBy" : {
                "name" : 1.0,
                "_id" : 0.0
            },
            "inputStage" : {
                "stage" : "IXSCAN",
                "keyPattern" : {
                    "name" : 1.0
                },
                "indexName" : "name_1",
                "isMultiKey" : false,
                "multiKeyPaths" : {
                    "name" : []
                },
                "isUnique" : false,
                "isSparse" : false,
                "isPartial" : false,
                "indexVersion" : 2,
                "direction" : "forward",
                "indexBounds" : {
                    "name" : [ 
                        "[\"1\", \"1\"]"
                    ]
                }
            }
        },
        "rejectedPlans" : []
    },
    "serverInfo" : {
        "host" : "dev03-ufile-69-21",
        "port" : 28018,
        "version" : "4.4.2-2-g200cba6",
        "gitVersion" : "200cba613b10a2edb9ced9def5c4a2000062330f"
    },
    "ok" : 1.0
}
```

对比不加`_id: 0`

```json
/* 1 */
{
    "queryPlanner" : {
        "plannerVersion" : 1,
        "namespace" : "test01.user",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "name" : {
                "$eq" : "1"
            }
        },
        "queryHash" : "D8E51AF6",
        "planCacheKey" : "1A14F94A",
        "winningPlan" : {
            "stage" : "PROJECTION_SIMPLE",
            "transformBy" : {
                "name" : 1.0
            },
            "inputStage" : {
                "stage" : "FETCH",
                "inputStage" : {
                    "stage" : "IXSCAN",
                    "keyPattern" : {
                        "name" : 1.0
                    },
                    "indexName" : "name_1",
                    "isMultiKey" : false,
                    "multiKeyPaths" : {
                        "name" : []
                    },
                    "isUnique" : false,
                    "isSparse" : false,
                    "isPartial" : false,
                    "indexVersion" : 2,
                    "direction" : "forward",
                    "indexBounds" : {
                        "name" : [ 
                            "[\"1\", \"1\"]"
                        ]
                    }
                }
            }
        },
        "rejectedPlans" : []
    },
    "serverInfo" : {
        "host" : "dev03-ufile-69-21",
        "port" : 28018,
        "version" : "4.4.2-2-g200cba6",
        "gitVersion" : "200cba613b10a2edb9ced9def5c4a2000062330f"
    },
    "ok" : 1.0
}
```

- IXSCAN, 索引扫描阶段
- PROJECTION，投射阶段，即提取对应的name字段
- FETCH，文档获取阶段
