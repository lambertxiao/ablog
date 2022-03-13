---
author: "Lambert Xiao"
title: "算法-topK"
date: "2022-03-13"
summary: "通常可以使用堆来解决topK的问题"
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
#   image: "/cover/golang-内存管理.png"
---

[4. 寻找两个正序数组的中位数](https://leetcode-cn.com/problems/median-of-two-sorted-arrays/)

给定两个大小分别为 m 和 n 的正序（从小到大）数组 nums1 和 nums2。请你找出并返回这两个正序数组的 中位数 。
算法的时间复杂度应该为 O(log (m+n)) 。

换个角度想一想：

1. 如果m+n为奇数，中位数也就是top((m+n)/2)；
2. 如果m+n是偶数，中位数也就是top((m+n)/2)和top((m+n)/2+1)的平均值

```go
func findMedianSortedArrays(nums1 []int, nums2 []int) float64 {
    length := len(nums1) + len(nums2)
    mid := length / 2
    
    if length % 2 == 1 {
        return float64(getKthElement(nums1, nums2, mid + 1))
    } 

    return float64(getKthElement(nums1, nums2, mid) + getKthElement(nums1, nums2, mid+1)) * 0.5
}

func getKthElement(nums1, nums2 []int, k int) int {
    m, n := len(nums1), len(nums2)
    from1, from2 := 0, 0 

    for {
        if from1 == len(nums1) {
            // nums1走完了，所以仅需在num2中找当前的第k小数，第k小的数的下标即为k - 1, 但需要从start点偏移而来
            return nums2[from2 + k - 1]
        }
        if from2 == len(nums2) {
            return nums1[from1 + k - 1]
        }

        // 找两个排序数组的最小数，即为两数组数组头的较小数
        if k == 1 {
            return min(nums1[from1], nums2[from2])
        }

        offset := k / 2 - 1
        to1 := min(from1 + offset, m - 1) // 越界则取最后一个
        to2 := min(from2 + offset, n - 1)

        // 比较nums1[k/2-1]和nums2[k/2-1]的大小，来减少范围
        if nums1[to1] < nums2[to2] {
            // k减去剔除的数量，比如原来是求第5小的数，现在剔除了2个较小的数，则目前应该求第3小的数了
            k -= (to1 - from1 + 1)
            // 剔除nums1[start1]
            from1 = to1 + 1
        } else {
            k -= (to2 - from2 + 1)
            from2 = to2 + 1
        }
    }
}
```

思路：

1. 在两个有序数组里求第K大的数，我们可以每次比较两个数组里k/2-1位置上的数

```
nums1: [1, 3, 8, 9]
nums2: [2, 5, 6, 7]
```

比如，我们在上面的两个数组里求第5大的数，那么k/2-1=1，所以比较nums1[1]和nums[2]的大小，这里 3 < 5

2. 这里首先nums1中比3小的有k/2-1个，nums2比5小的有k/2-1个，此时3又小于5，那么比3小的那k/2-1个数不可能是第K大的数

3. 把不可能的数从数组中划掉，得到

```
nums1: [8, 9]
nums2: [2, 5, 6, 7]
```

4. 此时因为减掉了两个数，我们要求的就不是第5大的数了，而是第3大的数

5. 重复以上逻辑，直到k等于1了，或者nums1或nums2中的某个数组空了


### 347. 前 K 个高频元素

[347. 前 K 个高频元素](https://leetcode-cn.com/problems/top-k-frequent-elements/)
给你一个整数数组 nums 和一个整数 k ，请你返回其中出现频率前 k 高的元素。你可以按 任意顺序 返回答案。

```go
func topKFrequent(nums []int, k int) []int {
    cnt := make(map[int]int)
    for _, num := range nums {
        cnt[num]++
    }

    keys := []int{}
    for k := range cnt {
        keys = append(keys, k)
    }

    sort.Slice(keys, func(i, j int) bool {
        return cnt[keys[i]] > cnt[keys[j]]
    })
    
    return keys[:k]
}
```

### 215. 数组中的第K个最大元素

[215. 数组中的第K个最大元素](https://leetcode-cn.com/problems/kth-largest-element-in-an-array/)
给定整数数组 nums 和整数 k，请返回数组中第 k 个最大的元素。

请注意，你需要找的是数组排序后的第 k 个最大的元素，而不是第 k 个不同的元素。

```go
func findKthLargest(nums []int, k int) int {
    h := hp{}
    for _, num := range nums {
        heap.Push(&h, num)
        if len(h) > k {
            heap.Pop(&h)
        }
    }
    return h[0]
}

type hp []int
func (h hp) Len() int { return len(h) }
func (h hp) Less(i, j int) bool { return h[i] < h[j] }
func (h hp) Swap(i, j int) { h[i], h[j] = h[j], h[i]} 
func (h *hp) Push(x interface{}) { *h = append(*h, x.(int)) }
func (h *hp) Pop() interface{} {
    old := *h
	n := len(old)
	x := old[n-1]
	*h = old[0:n-1]
	return x
}
```