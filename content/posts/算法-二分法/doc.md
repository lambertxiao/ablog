---
author: "Lambert Xiao"
title: "算法-二分法"
date: "2022-03-10"
summary: "最难不过二分，边界问题最蛋疼"
tags: ["算法", "二分法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/算法-二分法.png"
---

## 二分查找

做二分查找牢记循环不变量

### [704. 二分查找](https://leetcode-cn.com/problems/binary-search/)

给定一个 n 个元素有序的（升序）整型数组 nums 和一个目标值 target  ，写一个函数搜索 nums 中的 target，如果目标值存在返回下标，否则返回 -1。

```go
func search(nums []int, target int) int {
    l, r := 0, len(nums)
    for l < r {
        m := l + (r - l) >> 1
        num := nums[m]
        if num == target {
            return m
        } else if num > target {
            r = m // 循环不变量，一开始是左闭右开
        } else {
            l = m + 1
        }
    }
    return -1
}
```

### [33. 搜索旋转排序数组](https://leetcode-cn.com/problems/search-in-rotated-sorted-array/)

整数数组 nums 按升序排列，数组中的值 互不相同 。

在传递给函数之前，nums 在预先未知的某个下标 k（0 <= k < nums.length）上进行了 旋转，使数组变为 [nums[k], nums[k+1], ..., nums[n-1], nums[0], nums[1], ..., nums[k-1]]（下标 从 0 开始 计数）。例如， [0,1,2,4,5,6,7] 在下标 3 处经旋转后可能变为 [4,5,6,7,0,1,2] 。

给你 旋转后 的数组 nums 和一个整数 target ，如果 nums 中存在这个目标值 target ，则返回它的下标，否则返回 -1 。

```go
func search(nums []int, target int) int {
    l, r := 0, len(nums) - 1

    for l <= r {
        mid := l + (r - l) >> 1
        midv := nums[mid]
        if midv == target {
            return mid
        } else {
            if midv < nums[r] {
                if target > midv && target <= nums[r] {
                    l = mid + 1
                } else {
                    r = mid - 1
                }
            } else {
                if target >= nums[l] && target < midv {
                    r = mid - 1
                } else {
                    l = mid + 1
                }
            }
        }
    }
    return -1
}
```

### [34. 在排序数组中查找元素的第一个和最后一个位置](https://leetcode-cn.com/problems/find-first-and-last-position-of-element-in-sorted-array/)

给定一个按照升序排列的整数数组 nums，和一个目标值 target。找出给定目标值在数组中的开始位置和结束位置。
如果数组中不存在目标值 target，返回 [-1, -1]。

进阶：
你可以设计并实现时间复杂度为 O(log n) 的算法解决此问题吗？

> 变形题：对于有多个相同的数，查询左右边界

```go
func searchRange(nums []int, target int) []int {
    return []int{
        leftBound(nums, target),
        rightBound(nums, target),
    }
}

func leftBound(nums []int, target int) int {
    l, r := 0, len(nums)
    for l < r {
        m := l + (r - l) >> 1
        n := nums[m]
        if n >= target {
            r = m
        } else {
            l = m + 1
        }
    }
    
    if l < len(nums) && nums[l] == target {
        return l
    }
    return -1
}


func rightBound(nums []int, target int) int {
    l, r := 0, len(nums)
    for l < r {
        m := l + (r - l) >> 1
        n := nums[m]
        if n <= target {
            l = m + 1
        } else {
            r = m
        }
    }
    
    if r-1 >= 0 && nums[r-1] == target {
        return r - 1
    }
    return -1
}
```

### [287. 寻找重复数](https://leetcode-cn.com/problems/find-the-duplicate-number/)

给定一个包含 n + 1 个整数的数组 nums ，其数字都在 [1, n] 范围内（包括 1 和 n），可知至少存在一个重复的整数。
假设 nums 只有 一个重复的整数 ，返回 这个重复的数 。
你设计的解决方案必须 不修改 数组 nums 且只用常量级 O(1) 的额外空间。

```go
func findDuplicate(nums []int) int {
    // 抽屉原理：把 10 个苹果放进 9 个抽屉，一定存在某个抽屉放至少 2 个苹果。
    n := len(nums)
    l, r := 0, n - 1
    for l < r {
        // mid此时相当于[l,r]之间的中位数
        mid := l + (r - l) / 2
        
        cnt := 0
        for _, n := range nums {
            if n <= mid {
                cnt++
            }
        }

        // 如果有一半以上的数小于等于中位数，说明小的那一半里有重复
        if cnt > mid {
            r = mid
        } else {
            l = mid + 1
        }
    }
    return l
}
```


### [153. 寻找旋转排序数组中的最小值](https://leetcode-cn.com/problems/find-minimum-in-rotated-sorted-array/)


已知一个长度为 n 的数组，预先按照升序排列，经由 1 到 n 次 旋转 后，得到输入数组。例如，原数组 nums = [0,1,2,4,5,6,7] 在变化后可能得到：
若旋转 4 次，则可以得到 [4,5,6,7,0,1,2]
若旋转 7 次，则可以得到 [0,1,2,4,5,6,7]
注意，数组 [a[0], a[1], a[2], ..., a[n-1]] 旋转一次 的结果为数组 [a[n-1], a[0], a[1], a[2], ..., a[n-2]] 。

给你一个元素值 互不相同 的数组 nums ，它原来是一个升序排列的数组，并按上述情形进行了多次旋转。请你找出并返回数组中的 最小元素 。

你必须设计一个时间复杂度为 O(log n) 的算法解决此问题。

```go
func findMin(nums []int) int {
    left, right := 0, len(nums) - 1
    for left < right {
        mid := (left + right) / 2
        if nums[mid] > nums[right]  {
            left = mid + 1
        } else if nums[mid] < nums[right]  {
            right = mid
        }
    }

    return nums[left]
}
```

### [154. 寻找旋转排序数组中的最小值 II](https://leetcode-cn.com/problems/find-minimum-in-rotated-sorted-array-ii/)

已知一个长度为 n 的数组，预先按照升序排列，经由 1 到 n 次 旋转 后，得到输入数组。例如，原数组 nums = [0,1,4,4,5,6,7] 在变化后可能得到：
若旋转 4 次，则可以得到 [4,5,6,7,0,1,4]
若旋转 7 次，则可以得到 [0,1,4,4,5,6,7]
注意，数组 [a[0], a[1], a[2], ..., a[n-1]] 旋转一次 的结果为数组 [a[n-1], a[0], a[1], a[2], ..., a[n-2]] 。

给你一个可能存在 重复 元素值的数组 nums ，它原来是一个升序排列的数组，并按上述情形进行了多次旋转。请你找出并返回数组中的 最小元素 。

你必须尽可能减少整个过程的操作步骤。

```go
func findMin(nums []int) int {
    l, r := 0, len(nums) - 1

    for l < r {
        m := l + (r - l) >> 1
        if nums[m] > nums[r] {
            l = m + 1
        } else if nums[m] < nums[r] {
            r = m
        } else {
            r--
        }
    }
    return nums[l]
}
```

### 69. x 的平方根 

给你一个非负整数 x ，计算并返回 x 的 算术平方根 。
由于返回类型是整数，结果只保留 整数部分 ，小数部分将被 舍去 。
注意：不允许使用任何内置指数函数和算符，例如 pow(x, 0.5) 或者 x ** 0.5 。

```go
func mySqrt(x int) int {
    if x == 1 { return 1 }
    l, r := 0, x / 2 + 1

    // 左闭右开
    for l < r {
        mid := l + (r - l) / 2
        v := mid * mid 
        if v == x {
            return mid
        } else if v > x {
            r = mid
        } else {
            l = mid + 1
        }
    }
    if r * r > x {
        return r - 1
    }

    return r
}
```

### [162. 寻找峰值](https://leetcode-cn.com/problems/find-peak-element/)

峰值元素是指其值严格大于左右相邻值的元素。
给你一个整数数组 nums，找到峰值元素并返回其索引。数组可能包含多个峰值，在这种情况下，返回 任何一个峰值 所在位置即可。
你可以假设 nums[-1] = nums[n] = -∞ 。
你必须实现时间复杂度为 O(log n) 的算法来解决此问题。

```go
func findPeakElement(nums []int) int {
    l, r := 0, len(nums) - 1
    for l < r {
        mid := l + (r - l) / 2
        if nums[mid] > nums[mid+1] {
            r = mid
        } else {
            l = mid + 1
        }
    }
    return l
}
```