---
author: "Lambert Xiao"
title: "算法-只出现一次的数字"
date: "2022-03-27"
summary: "挺恶心的位运行"
tags: ["算法", "位运算"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 136. 只出现一次的数字

[136. 只出现一次的数字](https://leetcode-cn.com/problems/single-number/)
给定一个非空整数数组，除了某个元素只出现一次以外，其余每个元素均出现两次。找出那个只出现了一次的元素。

```go
func singleNumber(nums []int) int {
    var ans int32 = 0
    for i := 0; i < 32; i++ {
        var tmp int32 = 0
        for _, num := range nums {
            // 对于每一个数的每一个二进制位分别累加
            // 左移将需要计算的位置放到最右边，再按位与上1，目的是清空其他位的值
            tmp += (int32(num) >> i) & 1
        }
        // 由于存在一个元素仅出现一次，跟3取余后能得到目标元素的第i位上的值
        if tmp % 2 != 0 {
            ans |= 1 << i // 注意这里是利用1左移回去占位，并与ans按位加上
        }
    }
    
    return int(ans)
}
```

当然异或的方式也可以

```go
func singleNumber(nums []int) int {
    v := 0
    for _, num := range nums {
        v = v ^ num
    }
    return v
}
```

说明：你的算法应该具有线性时间复杂度。 你可以不使用额外空间来实现吗？

### 137. 只出现一次的数字 II

[137. 只出现一次的数字 II](https://leetcode-cn.com/problems/single-number-iii/)

给你一个整数数组 nums ，除某个元素仅出现 一次 外，其余每个元素都恰出现 三次 。请你找出并返回那个只出现了一次的元素。

假设对于数组 [4, 3, 3, 3, 2, 2, 2]，将所有的数看作二进制即

```
0100
0011
0011
0011
0010
0010
0010
```

对于32位int，如果我们将每一个二进制位都加起来（相当于上方数组的每一列相加），我们最终会得到 `0163`, 由于其余的数都出现了三次，所以每一位都和3取余可以得到 `0100`, 即能得到4

```go
func singleNumber(nums []int) int {
    var ans int32 = 0
    for i := 0; i < 32; i++ {
        var tmp int32 = 0
        for _, num := range nums {
            // 对于每一个数的每一个二进制位分别累加
            // 左移将需要计算的位置放到最右边，再按位与上1，目的是清空其他位的值
            tmp += (int32(num) >> i) & 1
        }
        // 由于存在一个元素仅出现一次，跟3取余后能得到目标元素的第i位上的值
        if tmp % 3 != 0 {
            ans |= 1 << i // 注意这里是利用1左移回去占位，并与ans按位加上
        }
    }
    
    return int(ans)
}
```

### 260. 只出现一次的数字 III

[260. 只出现一次的数字 III](https://leetcode-cn.com/problems/single-number-iii/)

给定一个整数数组 nums，其中恰好有两个元素只出现一次，其余所有元素均出现两次。 找出只出现一次的那两个元素。你可以按 任意顺序 返回答案。

进阶：你的算法应该具有线性时间复杂度。你能否仅使用常数空间复杂度来实现？

```
对于数字6和-6

原码
0000 0000 0000 0110
1000 0000 0000 0110

反码
0000 0000 0000 0110
1111 1111 1111 1001

补码
0000 0000 0000 0110
1111 1111 1111 1010

&后
0000 0000 0000 0010

可以看到 6 & -6 后，只保留了最末尾的1
```

```go
func singleNumber(nums []int) []int {
    xorVal := 0
    for _, num := range nums {
        xorVal ^= num
    }

    // &之后只保留了最末尾的1
    val := xorVal & -xorVal
    n1, n2 := 0, 0
    for _, num := range nums {
        // 这里其实是判断num在val最末尾1上的位是不是也是1
        if num & val == 0 {
            n1 ^= num
        } else {
            n2 ^= num
        }
    }

    return []int{n1, n2}
}
```
