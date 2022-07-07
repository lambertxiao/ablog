---
author: "Lambert Xiao"
title: "算法-位运算"
date: "2022-03-13"
summary: ""
tags: ["算法", "位运算"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 461. 汉明距离

[461. 汉明距离](https://leetcode-cn.com/problems/hamming-distance/)
两个整数之间的 [汉明距离](https://baike.baidu.com/item/%E6%B1%89%E6%98%8E%E8%B7%9D%E7%A6%BB) 指的是这两个数字对应二进制位不同的位置的数目。

给你两个整数 x 和 y，计算并返回它们之间的汉明距离。

```go
func hammingDistance(x int, y int) int {
    s := x ^ y
    // 汉明距离即为s中1的数量
    res := 0

    for s > 0 {
        // 判断最低位是不是1
        res += s & 1
        s >>= 1
    }
     
     return res
}
```

### 397. 整数替换

[397. 整数替换](https://leetcode-cn.com/problems/integer-replacement/)

给定一个正整数 n ，你可以做如下操作：

如果 n 是偶数，则用 n / 2替换 n 。
如果 n 是奇数，则可以用 n + 1或n - 1替换 n 。
返回 n 变为 1 所需的 最小替换次数 。

```go
func integerReplacement(n int) int {
    /**
     * 二进制观察处理法
     * 实现思路:
     *      最快的移动就是遇到2的次幂(例如数字16  10000 -> 01000 -> 00100 -> 00010 -> 00001)
     *      将二进制一直左移 最右为0时可以直接移动(例如数字6  000110 -> 000011)
     *      最右位为1时需把1变成0, 再移动(例如数字9  001001 -> 001000)
     *      故最优解就是如何在迭代中减少出现末尾1(就是什么时候+1, 什么时候-1 来实现过程中最少出现01或11结尾)
     * 得出以下结论:
     *      若n的二进制为 xxxx10, 则下一次处理 n = n/2 次数+1
     *      若n的二进制为 xxxx01, 则下一次处理 n = n/2 次数+2(即需要先-1再除以2, 故这里是加2) n > 1
     *      若n的二进制为 xxxx11, 则下一次处理 n = n/2 +1 次数+2(即需要先+1再除以2, 故这里是加2) n > 3
     *      特殊情况: 数字3  000011, 000011 -> 000010 -> 000001(两次即可)
     * 边界条件: 000001 -> 答案为0
     */

    cnt := 0
    for n != 1 {
        if n % 2 == 0 { // n为偶数
            cnt++
            n /= 2
        } else if n == 3 { // 特殊case
            cnt += 2
            n = 1
        } else if (n & 3) == 3 { // n的二进制格式为xxxxxx11
            n++
            cnt++
        } else { // n的二进制格式为xxxxxx01
            n--
            cnt++
        }
    }
    return cnt
}
```