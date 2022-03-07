---
author: "Lambert Xiao"
title: "Redis-实现分布式锁"
date: "2022-03-07"
summary: "只要是分布式应用，免不了要使用分布式锁"
tags: ["redis"]
categories: ["redis"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

Talk is cheap, show you the code

```go
package model

import (
	"censor-task-manager/pkg/utils"
	"context"

	log "github.com/sirupsen/logrus"

	"time"

	"github.com/go-redis/redis/v8"
)

const SYNC_INTERVAL = 20 * time.Second
const LOCK_EXPIRE_DURATION = 30 * time.Second

type DistributionNode struct {
	isMaster bool
	nodeId   string
	redis    *redis.Client
	ctx      context.Context
	lockKey  string

	// 同步间隔要小于锁的过期时间
	syncInterval       time.Duration
	lockExpireDuration time.Duration
}

func NewDistributionNode(redisHost, redisPassword, lockKey string) *DistributionNode {
	ctx := context.Background()
	client := redis.NewClient(&redis.Options{Addr: redisHost, Password: redisPassword})
	n := &DistributionNode{
		nodeId:             utils.Uuid(),
		redis:              client,
		ctx:                ctx,
		lockKey:            lockKey,
		syncInterval:       SYNC_INTERVAL,
		lockExpireDuration: LOCK_EXPIRE_DURATION,
	}

	return n
}

func (n *DistributionNode) Start() {
	ticker := time.NewTicker(n.syncInterval)

	for {
		locked, err := n.Lock()
		if err != nil {
			log.Error(err)
			time.Sleep(time.Second)
			continue
		}

		if locked {
			n.isMaster = true
		} else {
			master, err := n.getCurrMaster()
			if err != nil {
				log.Error(err)
				return
			}

			if master == n.nodeId {
				n.isMaster = true
			}
		}

		<-ticker.C
	}
}

func (n *DistributionNode) Lock() (bool, error) {
	r, err := n.redis.SetNX(n.ctx, n.lockKey, n.nodeId, n.lockExpireDuration).Result()
	if err != nil {
		return false, err
	}

	return r, nil
}

func (n *DistributionNode) Unlock() (bool, error) {
	lua := `
		if redis.call('GET', KEYS[1]) == ARGV[1] then
			return redis.call('DEL', KEYS[1])
		else
			return 0
		end
	`

	val, err := n.redis.Eval(n.ctx, lua, []string{n.lockKey}, []string{n.nodeId}).Result()
	if err != nil {
		return false, err
	}

	return val == int64(1), nil
}

func (n *DistributionNode) IsMaster() bool {
	return n.isMaster
}

func (n *DistributionNode) getCurrMaster() (string, error) {
	return n.redis.Get(n.ctx, n.lockKey).Result()
}
```
