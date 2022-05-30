---
author: "Lambert Xiao"
title: "golang-runtime"
date: "2022-03-25"
summary: ""
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

```go
func chansend(c *hchan, ep unsafe.Pointer, block bool, callerpc uintptr) bool
func chanrecv(c *hchan, ep unsafe.Pointer, block bool) (selected, received bool)
func deferproc(siz int32, fn *funcval)
```
