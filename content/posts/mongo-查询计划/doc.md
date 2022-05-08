---
author: "Lambert Xiao"
title: "MongoDB查询计划"
date: "2022-05-08"
summary: "什么是查询计划"
tags: ["mongo"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

MongoDB采用自底向上的方式来构造查询计划，每一个查询计划 (query plan）都会被分解为若千个有层次的阶段
(stage）。有意思的是，整个查询计划最终会呈现出一颗多叉树的形状。

![](../1.png)

整个计算过程是从下向上投递的，每一个阶段的计算结果都是其上层阶段的输入

```js
var collection = db.getCollection("practise");
var count = 10000;
var base = 10;
var items = [];
for (var i = 0; i <= count; i++) {
    var item = {};
    item.x = Math.round(Math.random() * base);
    item.y = Math.round(Math.random() * base);
    item.z = Math.round(Math.random() * base);
    item.did = "ITEM" + i;
    items.push(item);

    if (i % 1000 == 0) {
        collection.insertMany(items);
        items = [];
    }
}

db.getCollection('practise').ensureIndex({x: 1, y: 1, z: 1})
db.getCollection('practise').ensureIndex({did: 1})
```

### 全表扫描

```js
db.getCollection('practise').find({aaa: 11}).explain()

{
    ...
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "aaa" : {
                "$eq" : 11.0
            }
        },
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "COLLSCAN",
            "filter" : {
                "aaa" : {
                    "$eq" : 11.0
                }
            },
            "direction" : "forward"
        },
        "rejectedPlans" : []
    },
    ...
}
```

### 单键索引命中

```js
db.getCollection('practise').find({did: "ITEM24"}).explain()

{
    ...
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "did" : {
                "$eq" : "ITEM24"
            }
        },
        "queryHash" : "B4F08825",
        "planCacheKey" : "9F7BDA42",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "FETCH",
            "inputStage" : {
                "stage" : "IXSCAN",
                "keyPattern" : {
                    "did" : 1.0
                },
                "indexName" : "did_1",
                "isMultiKey" : false,
                "multiKeyPaths" : {
                    "did" : []
                },
                "isUnique" : false,
                "isSparse" : false,
                "isPartial" : false,
                "indexVersion" : 2,
                "direction" : "forward",
                "indexBounds" : {
                    "did" : [ 
                        "[\"ITEM24\", \"ITEM24\"]"
                    ]
                }
            }
        },
        "rejectedPlans" : []
    },
    ...
}

```

### 覆盖索引

```js
db.getCollection('practise').find({did: "ITEM24"}, {did: 1, _id: 0}).explain()

{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "did" : {
                "$eq" : "ITEM24"
            }
        },
        "queryHash" : "BA4C57C6",
        "planCacheKey" : "302BC8FB",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "PROJECTION_COVERED",
            "transformBy" : {
                "did" : 1.0,
                "_id" : 0.0
            },
            "inputStage" : {
                "stage" : "IXSCAN",
                "keyPattern" : {
                    "did" : 1.0
                },
                "indexName" : "did_1",
                "isMultiKey" : false,
                "multiKeyPaths" : {
                    "did" : []
                },
                "isUnique" : false,
                "isSparse" : false,
                "isPartial" : false,
                "indexVersion" : 2,
                "direction" : "forward",
                "indexBounds" : {
                    "did" : [ 
                        "[\"ITEM24\", \"ITEM24\"]"
                    ]
                }
            }
        },
        "rejectedPlans" : []
    },
}
```

### 列表查询+skip/limit

```js
db.getCollection('practise').find({x: {$gt: 3}}).skip(10).limit(5).explain()

{
    ...
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$gt" : 3.0
            }
        },
        "queryHash" : "39913629",
        "planCacheKey" : "CB9286EB",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "LIMIT",
            "limitAmount" : 5,
            "inputStage" : {
                "stage" : "FETCH",
                "inputStage" : {
                    "stage" : "SKIP",
                    "skipAmount" : 10,
                    "inputStage" : {
                        "stage" : "IXSCAN",
                        "keyPattern" : {
                            "x" : 1.0,
                            "y" : 1.0,
                            "z" : 1.0
                        },
                        "indexName" : "x_1_y_1_z_1",
                        "isMultiKey" : false,
                        "multiKeyPaths" : {
                            "x" : [],
                            "y" : [],
                            "z" : []
                        },
                        "isUnique" : false,
                        "isSparse" : false,
                        "isPartial" : false,
                        "indexVersion" : 2,
                        "direction" : "forward",
                        "indexBounds" : {
                            "x" : [ 
                                "(3.0, inf.0]"
                            ],
                            "y" : [ 
                                "[MinKey, MaxKey]"
                            ],
                            "z" : [ 
                                "[MinKey, MaxKey]"
                            ]
                        }
                    }
                }
            }
        },
        "rejectedPlans" : []
    },
    ...
}
```

### 内存排序

使用了`{x1: 1}`, 因此无法利用索引进行排序，只能在内存里排序。当内存排序超过了memLimit时，查询就会出错

```js
db.getCollection('practise').find({x: {$gt: 3}}).sort({x1: 1}).explain("executionStats")

{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$gt" : 3.0
            }
        },
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "SORT",
            "sortPattern" : {
                "x1" : 1
            },
            "memLimit" : 104857600,
            "type" : "simple",
            "inputStage" : {
                "stage" : "FETCH",
                "inputStage" : {
                    "stage" : "IXSCAN",
                    "keyPattern" : {
                        "x" : 1.0,
                        "y" : 1.0,
                        "z" : 1.0
                    },
                    "indexName" : "x_1_y_1_z_1",
                    "isMultiKey" : false,
                    "multiKeyPaths" : {
                        "x" : [],
                        "y" : [],
                        "z" : []
                    },
                    "isUnique" : false,
                    "isSparse" : false,
                    "isPartial" : false,
                    "indexVersion" : 2,
                    "direction" : "forward",
                    "indexBounds" : {
                        "x" : [ 
                            "(3.0, inf.0]"
                        ],
                        "y" : [ 
                            "[MinKey, MaxKey]"
                        ],
                        "z" : [ 
                            "[MinKey, MaxKey]"
                        ]
                    }
                }
            }
        },
        "rejectedPlans" : []
    },
}
```

### 组合索引无法命中

查询无法满足前缀匹配原则，实际上做了全表扫描

```js
db.getCollection('practise').find({y: 1, z: 3}).explain()

{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "$and" : [ 
                {
                    "y" : {
                        "$eq" : 1.0
                    }
                }, 
                {
                    "z" : {
                        "$eq" : 3.0
                    }
                }
            ]
        },
        "queryHash" : "2B5DAA81",
        "planCacheKey" : "189A1787",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "COLLSCAN",
            "filter" : {
                "$and" : [ 
                    {
                        "y" : {
                            "$eq" : 1.0
                        }
                    }, 
                    {
                        "z" : {
                            "$eq" : 3.0
                        }
                    }
                ]
            },
            "direction" : "forward"
        },
        "rejectedPlans" : []
    },
}
```

### 组合索引排序命中

`sort({y: -1, z: -1})` y和z都使用了降序，所以可以使用索引排序

```js
db.getCollection('practise').find({x: 1}).sort({y: -1, z: -1}).limit(5).explain()


{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$eq" : 1.0
            }
        },
        "queryHash" : "D1E516FC",
        "planCacheKey" : "36B48F45",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "LIMIT",
            "limitAmount" : 5,
            "inputStage" : {
                "stage" : "FETCH",
                "inputStage" : {
                    "stage" : "IXSCAN",
                    "keyPattern" : {
                        "x" : 1.0,
                        "y" : 1.0,
                        "z" : 1.0
                    },
                    "indexName" : "x_1_y_1_z_1",
                    "isMultiKey" : false,
                    "multiKeyPaths" : {
                        "x" : [],
                        "y" : [],
                        "z" : []
                    },
                    "isUnique" : false,
                    "isSparse" : false,
                    "isPartial" : false,
                    "indexVersion" : 2,
                    "direction" : "backward",
                    "indexBounds" : {
                        "x" : [ 
                            "[1.0, 1.0]"
                        ],
                        "y" : [ 
                            "[MaxKey, MinKey]"
                        ],
                        "z" : [ 
                            "[MaxKey, MinKey]"
                        ]
                    }
                }
            }
        },
        "rejectedPlans" : []
    },
}

```

### 组合索引命中，内存排序

`sort({y: 1, z: -1})` y和z排序方向不同，所以只能在内存中排序。需要注意的是，这里的内存排序是基于索引的而不是文档的，但在mongodb4.0及以前的版本中，对于这种查询的排序是基于文档的，也就是先执行FETCH再执行SORT。

```js

db.getCollection('practise').find({x: 1}).sort({y: 1, z: -1}).limit(5).explain()


{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$eq" : 1.0
            }
        },
        "queryHash" : "048FB511",
        "planCacheKey" : "3CE59AC2",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "FETCH",
            "inputStage" : {
                "stage" : "SORT",
                "sortPattern" : {
                    "y" : 1,
                    "z" : -1
                },
                "memLimit" : 104857600,
                "limitAmount" : 5,
                "type" : "default",
                "inputStage" : {
                    "stage" : "IXSCAN",
                    "keyPattern" : {
                        "x" : 1.0,
                        "y" : 1.0,
                        "z" : 1.0
                    },
                    "indexName" : "x_1_y_1_z_1",
                    "isMultiKey" : false,
                    "multiKeyPaths" : {
                        "x" : [],
                        "y" : [],
                        "z" : []
                    },
                    "isUnique" : false,
                    "isSparse" : false,
                    "isPartial" : false,
                    "indexVersion" : 2,
                    "direction" : "forward",
                    "indexBounds" : {
                        "x" : [ 
                            "[1.0, 1.0]"
                        ],
                        "y" : [ 
                            "[MinKey, MaxKey]"
                        ],
                        "z" : [ 
                            "[MinKey, MaxKey]"
                        ]
                    }
                }
            }
        },
        "rejectedPlans" : []
    },
}
```

### 组合索引命中，范围+排序

```js
db.getCollection('practise').find({x: {$gt: 3}}).sort({x: 1, y: 1, z: 1}).explain()

{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$gt" : 3.0
            }
        },
        "queryHash" : "D7099141",
        "planCacheKey" : "4B559A11",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "FETCH",
            "inputStage" : {
                "stage" : "IXSCAN",
                "keyPattern" : {
                    "x" : 1.0,
                    "y" : 1.0,
                    "z" : 1.0
                },
                "indexName" : "x_1_y_1_z_1",
                "isMultiKey" : false,
                "multiKeyPaths" : {
                    "x" : [],
                    "y" : [],
                    "z" : []
                },
                "isUnique" : false,
                "isSparse" : false,
                "isPartial" : false,
                "indexVersion" : 2,
                "direction" : "forward",
                "indexBounds" : {
                    "x" : [ 
                        "(3.0, inf.0]"
                    ],
                    "y" : [ 
                        "[MinKey, MaxKey]"
                    ],
                    "z" : [ 
                        "[MinKey, MaxKey]"
                    ]
                }
            }
        },
        "rejectedPlans" : []
    },
}
```

### 不合适的组合索引，范围+排序

x不是等值匹配，因此`{y: 1, z: 1}`的排序无法利用组合索引的顺序，此时产生了内存排序

```js
db.getCollection('practise').find({x: {$gt: 3}}).sort({y: 1, z: 1}).explain()


{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$gt" : 3.0
            }
        },
        "queryHash" : "916DB19C",
        "planCacheKey" : "B7596367",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "FETCH",
            "inputStage" : {
                "stage" : "SORT",
                "sortPattern" : {
                    "y" : 1,
                    "z" : 1
                },
                "memLimit" : 104857600,
                "type" : "default",
                "inputStage" : {
                    "stage" : "IXSCAN",
                    "keyPattern" : {
                        "x" : 1.0,
                        "y" : 1.0,
                        "z" : 1.0
                    },
                    "indexName" : "x_1_y_1_z_1",
                    "isMultiKey" : false,
                    "multiKeyPaths" : {
                        "x" : [],
                        "y" : [],
                        "z" : []
                    },
                    "isUnique" : false,
                    "isSparse" : false,
                    "isPartial" : false,
                    "indexVersion" : 2,
                    "direction" : "forward",
                    "indexBounds" : {
                        "x" : [ 
                            "(3.0, inf.0]"
                        ],
                        "y" : [ 
                            "[MinKey, MaxKey]"
                        ],
                        "z" : [ 
                            "[MinKey, MaxKey]"
                        ]
                    }
                }
            }
        },
        "rejectedPlans" : []
    },
}
```

### 合并排序

这里使用$in将目标值锁定在有限的若干个值上，数据库会使用归并排序的方式来保证结果的有序性

```js
db.getCollection('practise').find({x: {$in: [1, 2, 3, 4]}}).sort({y: 1}).explain()

{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "x" : {
                "$in" : [ 
                    1.0, 
                    2.0, 
                    3.0, 
                    4.0
                ]
            }
        },
        "queryHash" : "C28AC753",
        "planCacheKey" : "AB92D2F0",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "FETCH",
            "inputStage" : {
                "stage" : "SORT_MERGE",
                "sortPattern" : {
                    "y" : 1.0
                },
                "inputStages" : [ 
                    {
                        "stage" : "IXSCAN",
                        "keyPattern" : {
                            "x" : 1.0,
                            "y" : 1.0,
                            "z" : 1.0
                        },
                        "indexName" : "x_1_y_1_z_1",
                        "isMultiKey" : false,
                        "multiKeyPaths" : {
                            "x" : [],
                            "y" : [],
                            "z" : []
                        },
                        "isUnique" : false,
                        "isSparse" : false,
                        "isPartial" : false,
                        "indexVersion" : 2,
                        "direction" : "forward",
                        "indexBounds" : {
                            "x" : [ 
                                "[1.0, 1.0]"
                            ],
                            "y" : [ 
                                "[MinKey, MaxKey]"
                            ],
                            "z" : [ 
                                "[MinKey, MaxKey]"
                            ]
                        }
                    }, 
                    {
                        "stage" : "IXSCAN",
                        "keyPattern" : {
                            "x" : 1.0,
                            "y" : 1.0,
                            "z" : 1.0
                        },
                        "indexName" : "x_1_y_1_z_1",
                        "isMultiKey" : false,
                        "multiKeyPaths" : {
                            "x" : [],
                            "y" : [],
                            "z" : []
                        },
                        "isUnique" : false,
                        "isSparse" : false,
                        "isPartial" : false,
                        "indexVersion" : 2,
                        "direction" : "forward",
                        "indexBounds" : {
                            "x" : [ 
                                "[2.0, 2.0]"
                            ],
                            "y" : [ 
                                "[MinKey, MaxKey]"
                            ],
                            "z" : [ 
                                "[MinKey, MaxKey]"
                            ]
                        }
                    }, 
                    {
                        "stage" : "IXSCAN",
                        "keyPattern" : {
                            "x" : 1.0,
                            "y" : 1.0,
                            "z" : 1.0
                        },
                        "indexName" : "x_1_y_1_z_1",
                        "isMultiKey" : false,
                        "multiKeyPaths" : {
                            "x" : [],
                            "y" : [],
                            "z" : []
                        },
                        "isUnique" : false,
                        "isSparse" : false,
                        "isPartial" : false,
                        "indexVersion" : 2,
                        "direction" : "forward",
                        "indexBounds" : {
                            "x" : [ 
                                "[3.0, 3.0]"
                            ],
                            "y" : [ 
                                "[MinKey, MaxKey]"
                            ],
                            "z" : [ 
                                "[MinKey, MaxKey]"
                            ]
                        }
                    }, 
                    {
                        "stage" : "IXSCAN",
                        "keyPattern" : {
                            "x" : 1.0,
                            "y" : 1.0,
                            "z" : 1.0
                        },
                        "indexName" : "x_1_y_1_z_1",
                        "isMultiKey" : false,
                        "multiKeyPaths" : {
                            "x" : [],
                            "y" : [],
                            "z" : []
                        },
                        "isUnique" : false,
                        "isSparse" : false,
                        "isPartial" : false,
                        "indexVersion" : 2,
                        "direction" : "forward",
                        "indexBounds" : {
                            "x" : [ 
                                "[4.0, 4.0]"
                            ],
                            "y" : [ 
                                "[MinKey, MaxKey]"
                            ],
                            "z" : [ 
                                "[MinKey, MaxKey]"
                            ]
                        }
                    }
                ]
            }
        },
        "rejectedPlans" : []
    },
}
```

### 跨索引的合并排序

```js
db.practise.ensureIndex({x: 1, z: 1});
db.practise.ensureIndex({y: 1, z: 1});

db.getCollection('practise').find({$or: [{x: 1}, {y: 1}]}).sort({z: 1}).explain()

{
    "queryPlanner" : {
        "namespace" : "test.practise",
        "indexFilterSet" : false,
        "parsedQuery" : {
            "$or" : [ 
                {
                    "x" : {
                        "$eq" : 1.0
                    }
                }, 
                {
                    "y" : {
                        "$eq" : 1.0
                    }
                }
            ]
        },
        "queryHash" : "56592F73",
        "planCacheKey" : "CE19B698",
        "maxIndexedOrSolutionsReached" : false,
        "maxIndexedAndSolutionsReached" : false,
        "maxScansToExplodeReached" : false,
        "winningPlan" : {
            "stage" : "SUBPLAN",
            "inputStage" : {
                "stage" : "FETCH",
                "inputStage" : {
                    "stage" : "SORT_MERGE",
                    "sortPattern" : {
                        "z" : 1.0
                    },
                    "inputStages" : [ 
                        {
                            "stage" : "IXSCAN",
                            "keyPattern" : {
                                "x" : 1.0,
                                "z" : 1.0
                            },
                            "indexName" : "x_1_z_1",
                            "isMultiKey" : false,
                            "multiKeyPaths" : {
                                "x" : [],
                                "z" : []
                            },
                            "isUnique" : false,
                            "isSparse" : false,
                            "isPartial" : false,
                            "indexVersion" : 2,
                            "direction" : "forward",
                            "indexBounds" : {
                                "x" : [ 
                                    "[1.0, 1.0]"
                                ],
                                "z" : [ 
                                    "[MinKey, MaxKey]"
                                ]
                            }
                        }, 
                        {
                            "stage" : "IXSCAN",
                            "keyPattern" : {
                                "y" : 1.0,
                                "z" : 1.0
                            },
                            "indexName" : "y_1_z_1",
                            "isMultiKey" : false,
                            "multiKeyPaths" : {
                                "y" : [],
                                "z" : []
                            },
                            "isUnique" : false,
                            "isSparse" : false,
                            "isPartial" : false,
                            "indexVersion" : 2,
                            "direction" : "forward",
                            "indexBounds" : {
                                "y" : [ 
                                    "[1.0, 1.0]"
                                ],
                                "z" : [ 
                                    "[MinKey, MaxKey]"
                                ]
                            }
                        }
                    ]
                }
            }
        },
        "rejectedPlans" : []
    },
}
```