---
author: "Lambert Xiao"
title: "算法-数组"
date: "2022-03-13"
summary: "与数组相关的算法题可以又各种骚操作"
tags: ["算法", "动态规划", "数组"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

### 11. 盛最多水的容器

[11. 盛最多水的容器](https://leetcode-cn.com/problems/container-with-most-water/)
给定一个长度为 n 的整数数组 height 。有 n 条垂线，第 i 条线的两个端点是 (i, 0) 和 (i, height[i]) 。

找出其中的两条线，使得它们与 x 轴共同构成的容器可以容纳最多的水。

返回容器可以储存的最大水量。

说明：你不能倾斜容器。

```go
func maxArea(height []int) int {
    l, r := 0, len(height) - 1

    ans := 0
    for l < r {
        area := min(height[l], height[r]) * (r - l)
        ans = max(ans, area)

        if height[l] < height[r] {
            l++
        } else {
            r--
        }
    }
    return ans
}
```

### 42. 接雨水

[42. 接雨水](https://leetcode-cn.com/problems/trapping-rain-water/)
给定 n 个非负整数表示每个宽度为 1 的柱子的高度图，计算按此排列的柱子，下雨之后能接多少雨水。

```go
// 动态规划，提前计算好左右两边的最大高度
func trap(height []int) int {
    n := len(height)
    leftMax, rightMax := make([]int, n), make([]int, n)

    leftMax[0] = height[0]
    for i := 1; i < n; i++ {
        leftMax[i] = max(leftMax[i-1], height[i])
    }

    rightMax[n-1] = height[n-1]
    for i := n - 2; i >= 0; i-- {
        rightMax[i] = max(rightMax[i+1], height[i])
    }

    ans := 0
    for i, h := range height  {
        ans += min(leftMax[i], rightMax[i]) - h
    }
    return ans
}

func trap2(height []int) int {
    // 每次计算当前的柱子怎么接多少水
    // 每个柱子的接水量 = min(往左最大高度，往右最大的高度) - 当前珠子高度
    // res += min(l_max, r_max) - height[i]
    l := len(height)
    left := 0
    right := l - 1
    leftMax := height[0]
    rightMax := height[l-1]
    res := 0

    for left <= right {
        leftMax = max(leftMax, height[left])
        rightMax = max(rightMax, height[right])
        
        if leftMax < rightMax {
            res += leftMax - height[left]
            left++
        } else {
            res += rightMax - height[right]
            right--
        }
    }

    return res
}
```

### 49. 字母异位词分组

[49. 字母异位词分组](https://leetcode-cn.com/problems/group-anagrams/)
给你一个字符串数组，请你将 字母异位词 组合在一起。可以按任意顺序返回结果列表。

字母异位词 是由重新排列源单词的字母得到的一个新单词，所有源单词中的字母通常恰好只用一次。

```go
func groupAnagrams(strs []string) [][]string {
    statistic := make(map[[26]int][]string)

    for _, str := range strs {
        // 计算出每个字符串每个字符出现的次数
        cnt := [26]int{}
        for _, c := range str {
            asiic := c - 'a'
            cnt[asiic]++
        }
        statistic[cnt] = append(statistic[cnt], str)
    }

    res := [][]string{}
    for _, item := range statistic {
        res = append(res, item)
    }

    return res
}
```

### 53. 最大子数组和

[53. 最大子数组和](https://leetcode-cn.com/problems/maximum-subarray/)
给你一个整数数组 nums ，请你找出一个具有最大和的连续子数组（子数组最少包含一个元素），返回其最大和。

子数组 是数组中的一个连续部分。

```go
func maxSubArray(nums []int) int {
    l := len(nums)
    max := nums[0]

    for i := 1; i < l; i++ {
        if nums[i] + nums[i-1] > nums[i] {
            // 这里利用nums[i]直接记录每次的累加和
            nums[i] = nums[i] + nums[i-1]
        }

        if nums[i] > max {
            max = nums[i]
        } 
    }

    return max
}
```

### 56. 合并区间

[56. 合并区间](https://leetcode-cn.com/problems/merge-intervals/)
以数组 intervals 表示若干个区间的集合，其中单个区间为 intervals[i] = [starti, endi] 。请你合并所有重叠的区间，并返回 一个不重叠的区间数组，该数组需恰好覆盖输入中的所有区间 。

```go
func merge(intervals [][]int) [][]int {
    sort.Slice(intervals, func(i, j int) bool {
        return intervals[i][0] < intervals[j][0]
    })

    ans := [][]int{intervals[0]}
    for i := 1; i < len(intervals); i++ {
        last := ans[len(ans)-1]
        if last[1] < intervals[i][0] { // 没有交集
            ans = append(ans, intervals[i])
        } else { 
            last[1] = max(last[1], intervals[i][1]) // 有交集，更新右边界
        }
    }

    return ans
}
```

### 57. 插入区间

[57. 插入区间](https://leetcode-cn.com/problems/insert-interval/)
给你一个 无重叠的 ，按照区间起始端点排序的区间列表。

在列表中插入一个新的区间，你需要确保列表中的区间仍然有序且不重叠（如果有必要的话，可以合并区间）。

```go
func insert(intervals [][]int, newInterval []int) [][]int {
    ans := [][]int{}
    left, right := 0, 1

    merged := false
    for _, interval := range intervals {
        // 没有交集
        if interval[right] < newInterval[left] {
            ans = append(ans, interval)
        } else if interval[left] > newInterval[right] {
            // 后面不会在遇到有重叠的区间了，所以合并完成
            if !merged {
                ans = append(ans, newInterval)
                merged = true
            }
            ans = append(ans, interval)
        } else {
            // 需要合并
            newInterval[left] = min(newInterval[left], interval[left])
            newInterval[right] = max(newInterval[right], interval[right])
        }
    }

    if !merged {
        ans = append(ans, newInterval)
    }

    return ans
}

func max(x, y int) int {
    if x > y { return x }
    return y
}

func min(x, y int) int {
    if x < y { return x }
    return y
}
```

### 75. 颜色分类

[75. 颜色分类](https://leetcode-cn.com/problems/sort-colors/)
给定一个包含红色、白色和蓝色、共 n 个元素的数组 nums ，[原地](https://baike.baidu.com/item/%E5%8E%9F%E5%9C%B0%E7%AE%97%E6%B3%95)对它们进行排序，使得相同颜色的元素相邻，并按照红色、白色、蓝色顺序排列。

我们使用整数 0、 1 和 2 分别表示红色、白色和蓝色。

必须在不使用库的sort函数的情况下解决这个问题。

```go
func sortColors(nums []int)  {
    p0, p1 := 0, 0

    for i, n := range nums {
        if n == 1 {
            nums[i], nums[p1] = nums[p1], nums[i]
            p1++
        } else if n == 0 {
            nums[i], nums[p0] = nums[p0], nums[i]
            if p0 < p1 {
                nums[i], nums[p1] = nums[p1], nums[i]
            }
            p0++
            p1++
        }
    }
}
```

### 581. 最短无序连续子数组

[581. 最短无序连续子数组](https://leetcode-cn.com/problems/shortest-unsorted-continuous-subarray/)
给你一个整数数组 nums ，你需要找出一个 连续子数组 ，如果对这个子数组进行升序排序，那么整个数组都会变为升序排序。

请你找出符合题意的 最短 子数组，并输出它的长度。

```go
func findUnsortedSubarray(nums []int) int {
    l, r, size := -1, -1, len(nums)

    leftMax, rightMin := math.MinInt32, math.MaxInt32
    for i, leftNum := range nums {
        // 从左往右
        if leftMax > leftNum {
            // 如果存在左边的数比当前的数大，则说明现在还不在升序区，更新r的位置
            r = i
        } else {
            leftMax = leftNum
        }

        rightNum := nums[size-i-1]
        // 从右往左
        if rightMin < rightNum {
            // 如果右边存在比当前更小的数，则说明现在还不在升序区，更新l的位置
            l = size - i - 1
        } else {
            rightMin = rightNum
        }
    }

    if l == -1 || r == -1 {
        return 0
    }

    return r - l + 1
}
```

### 448. 找到所有数组中消失的数字

[448. 找到所有数组中消失的数字](https://leetcode-cn.com/problems/find-all-numbers-disappeared-in-an-array/)
给你一个含 n 个整数的数组 nums ，其中 nums[i] 在区间 [1, n] 内。请你找出所有在 [1, n] 范围内但没有出现在 nums 中的数字，并以数组的形式返回结果。

负数标记法

```go
func findDisappearedNumbers(nums []int) []int {
    for _, num := range nums {
        // 将数字标记为负数
        idx := abs(num)-1
        nums[idx] = -abs(nums[idx])
    }
    ans := []int{}
    for i, num := range nums {
        if num > 0 {
            ans = append(ans, i + 1)
        }
    }
    return ans
}

func abs(x int) int {
    if x > 0 { return x }
    return -x
}
```

### 442. 数组中重复的数据

[442. 数组中重复的数据](https://leetcode-cn.com/problems/find-all-duplicates-in-an-array/)
给你一个长度为 n 的整数数组 nums ，其中 nums 的所有整数都在范围 [1, n] 内，且每个整数出现 一次 或 两次 。请你找出所有出现 两次 的整数，并以数组形式返回。

你必须设计并实现一个时间复杂度为 O(n) 且仅使用常量额外空间的算法解决此问题。

```go
func findDuplicates(nums []int) []int {
    ans := []int{}
    for _, num := range nums {
        idx := abs(num)-1
        if nums[idx] < 0 {
            ans = append(ans, abs(num))
        }
        nums[idx] = -nums[idx]
    }

    return ans
}
```

### 416. 分割等和子集

[416. 分割等和子集](https://leetcode-cn.com/problems/partition-equal-subset-sum/)
给你一个 只包含正整数 的 非空 数组 nums 。请你判断是否可以将这个数组分割成两个子集，使得两个子集的元素和相等。

```go
func canPartition(nums []int) bool {
    // dp[i][j] 表示为在nums[0..i-1]中能找到数字之和为j
    n := len(nums)
    if n == 0 || n == 1 { return false }

    sum, maxNum := 0, 0
    for _, num := range nums {
        if num > maxNum {
            maxNum = num
        }
        sum += num
    }

    // 不能等分
    if sum % 2 != 0 {
        return false
    }

    target := sum / 2
    // 如果有单个值已经超过了一半，直接false
    if maxNum > target {
        return false
    }

    dp := make([][]bool, n)
    for i := range dp {
        dp[i] = make([]bool, target + 1)
    }
    
    for i := range dp {
        dp[i][0] = true
    }

    dp[0][nums[0]] = true

    for i := 1; i < n; i++ {
        v := nums[i]
        for j := 0; j <= target; j++ {
            if j >= v {
                dp[i][j] = dp[i-1][j] || dp[i-1][j-v]
            } else {
                dp[i][j] = dp[i-1][j]
            }
        }
    }

    return dp[n-1][target]
}
```

### 406. 根据身高重建队列

[406. 根据身高重建队列](https://leetcode-cn.com/problems/queue-reconstruction-by-height/)
假设有打乱顺序的一群人站成一个队列，数组 people 表示队列中一些人的属性（不一定按顺序）。每个 people[i] = [hi, ki] 表示第 i 个人的身高为 hi ，前面 正好 有 ki 个身高大于或等于 hi 的人。

请你重新构造并返回输入数组 people 所表示的队列。返回的队列应该格式化为数组 queue ，其中 queue[j] = [hj, kj] 是队列中第 j 个人的属性（queue[0] 是排在队列前面的人）。

```go
func reconstructQueue(people [][]int) [][]int {
    // 先按身高降序排列
    sort.Slice(people, func(i, j int) bool {
        if people[i][0] == people[j][0] {
            return people[i][1] < people[j][1] // 身高相同情况下按k升序排列
        }
        return people[i][0] > people[j][0] // 否则按身高降序排列
    })

    res := make([][]int, len(people))
    for i := 0; i < len(people); i++ {
        // 将people插到对应的位置
        idx := people[i][1]
        // 如果原先位置上有元素需要挪开位置
        copy(res[idx+1:], res[idx:]) // 将res[idx:]搬到res[idx+1:]，从而空出来res[i]
        res[idx] = people[i]
    }

    return res
}
```

### 283. 移动零

[283. 移动零](https://leetcode-cn.com/problems/move-zeroes/)
给定一个数组 nums，编写一个函数将所有 0 移动到数组的末尾，同时保持非零元素的相对顺序。

请注意 ，必须在不复制数组的情况下原地对数组进行操作。

```java
public void moveZeroes(int[] nums) {
    if (nums == null || nums.length == 0) {
        return;
    }
    
    // 记录可被替换元素的下标
    int index = 0;
    
    for (int i = 0; i < nums.length; i++) {
        if (nums[i] != 0) {
            nums[index] = nums[i];
            index++;
        }
    }
    
    while (index < nums.length) {
        nums[index++] = 0;
    }
}
```
### 74. 搜索二维矩阵

[74. 搜索二维矩阵](https://leetcode-cn.com/problems/search-a-2d-matrix/)
编写一个高效的算法来判断 m x n 矩阵中，是否存在一个目标值。该矩阵具有如下特性：

每行中的整数从左到右按升序排列。
每行的第一个整数大于前一行的最后一个整数。

```go
func searchMatrix(matrix [][]int, target int) bool {
    m := len(matrix)
    n := len(matrix[0])
    i, j := 0, n - 1
    
    for i < m && j >= 0 {
        val := matrix[i][j]
        if val == target {
            return true
        }

        if val > target {
            j--
        } else if val < target {
            i++
        }
    }

    return false
}
```

### 240. 搜索二维矩阵 II

[240. 搜索二维矩阵 II](https://leetcode-cn.com/problems/search-a-2d-matrix-ii/)
编写一个高效的算法来搜索 m x n 矩阵 matrix 中的一个目标值 target 。该矩阵具有以下特性：

每行的元素从左到右升序排列。
每列的元素从上到下升序排列。

```go
func searchMatrix(matrix [][]int, target int) bool {
    m := len(matrix)
    n := len(matrix[0])
    i, j := 0, n - 1
    
    for i < m && j >= 0 {
        val := matrix[i][j]
        if val == target {
            return true
        }

        if val > target {
            j--
        } else if val < target {
            i++
        }
    }

    return false
}
```

### 238. 除自身以外数组的乘积

[238. 除自身以外数组的乘积](https://leetcode-cn.com/problems/product-of-array-except-self/)
给你一个整数数组 nums，返回 数组 answer ，其中 answer[i] 等于 nums 中除 nums[i] 之外其余各元素的乘积 。

题目数据 保证 数组 nums之中任意元素的全部前缀元素和后缀的乘积都在  32 位 整数范围内。

请不要使用除法，且在 O(n) 时间复杂度内完成此题。

```go
func productExceptSelf(nums []int) []int {
    n := len(nums)
    // 本题解法为前缀积和后缀积
    ans := make([]int, n)

    // 先从左到右，计算前缀积
    ans[0] = 1
    for i := 1; i < n; i++ {
        ans[i] = ans[i-1] * nums[i-1]
    }

    // 由于控制了O(1)的时间复杂度，使用一个变量记录从右往左的前缀积
    r := 1 
    for i := n - 1; i >= 0; i-- {
        ans[i] = ans[i] * r
        // rs[i] = rs[i+1] * nums[i+1]
        r *= nums[i]
    }
    return ans
}
```
### 169. 多数元素

[169. 多数元素](https://leetcode-cn.com/problems/majority-element/)
给定一个大小为 n 的数组，找到其中的多数元素。多数元素是指在数组中出现次数 大于 ⌊ n/2 ⌋ 的元素。

你可以假设数组是非空的，并且给定的数组总是存在多数元素。

摩尔投票法

```go
func majorityElement(nums []int) int {
    // 当前的candidate
    candidate := nums[0]
    // 当前candidate获得的票数
    count := 1

    for i := 1; i < len(nums); i++ {
        // 如果当前candidate没有票了，更换candidate
        if count == 0 {
            candidate = nums[i]
            count = 1
            continue
        }
        
        // 如果当前元素和candidate相同，则票数+1
        if candidate == nums[i] {
            count++
        // 如果当前元素和candidate不相同，则两两抵消，票数-1
        } else {
            count--
        }
    }
    
    return candidate
}
```

### 229. 求众数 II

[229. 求众数 II](https://leetcode-cn.com/problems/majority-element-ii/)
给定一个大小为 n 的整数数组，找出其中所有出现超过 ⌊ n/3 ⌋ 次的元素。


```go
func majorityElement(nums []int) []int {
    if len(nums) < 2 {
        return nums
    }

    candidate1, candidate2 := nums[0], nums[1]
    cnt1, cnt2 := 0, 0

    for _, num := range nums {
        if num == candidate1 {
            cnt1++
            continue
        }
        if num == candidate2 {
            cnt2++
            continue
        }

        // 一号候选人没有票，则当前num成为候选人
        if cnt1 == 0 {
            candidate1 = num
            cnt1 = 1
            continue
        }

        // 二号候选人没有票，则当前num成为候选人
        if cnt2 == 0 {
            candidate2 = num
            cnt2 = 1
            continue
        }

        // 两人都有票，和当前num相互抵消
        cnt1--
        cnt2--
    }

    // 计算两个候选人的个数
    cnt1, cnt2 = 0, 0
    for _, num := range nums {
        if num == candidate1 {
            cnt1++
        }
        if num == candidate2 {
            cnt2++
        }
    }

    ans := []int{}
    if cnt1 > len(nums) / 3 {
        ans = append(ans, candidate1)
    }
    if candidate2 != candidate1 && cnt2 > len(nums) / 3 {
        ans = append(ans, candidate2)
    }

    return ans
}
```

### 152. 乘积最大子数组

[152. 乘积最大子数组](https://leetcode-cn.com/problems/maximum-product-subarray/)
给你一个整数数组 nums ，请你找出数组中乘积最大的非空连续子数组（该子数组中至少包含一个数字），并返回该子数组所对应的乘积。

测试用例的答案是一个 32-位 整数。

子数组 是数组的连续子序列。

```go
func maxProduct(nums []int) int {
    maxSum := math.MinInt16
    imax := 1
    imin := 1

    for _, v := range nums {
        // 当当前元素为负值时，最大变最小，最小变最大
        if v < 0 {
            temp := imax
            imax = imin
            imin = temp
        }
        imax = max(imax * v, v)
        imin = min(imin * v, v)
        maxSum = max(maxSum, imax)
    }

    return maxSum
}
```
### 139. 单词拆分

[139. 单词拆分](https://leetcode-cn.com/problems/word-break/)
给你一个字符串 s 和一个字符串列表 wordDict 作为字典。请你判断是否可以利用字典中出现的单词拼接出 s 。

注意：不要求字典中出现的单词全部都使用，并且字典中的单词可以重复使用。

```go
func wordBreak(s string, wordDict []string) bool {
    mem := make(map[string]bool)
    for _, word := range wordDict {
        mem[word] = true
    }

    size := len(s)
    // dp[i]表示s[0..i-1]能否由wordDict组成
    dp := make([]bool, size + 1)
    dp[0] = true // 空字符串

    for i := 1; i <= size; i++ {
        for j := 0; j <= i; j++ {
            if dp[j] && mem[s[j:i]] {
                dp[i] = true
            }
        }
    }

    return dp[size]
}
```

### 164. 最大间距

[164. 最大间距](https://leetcode-cn.com/problems/maximum-gap/)

给定一个无序的数组 nums，返回 数组在排序之后，相邻元素之间最大的差值 。如果数组元素个数小于 2，则返回 0 。

您必须编写一个在「线性时间」内运行并使用「线性额外空间」的算法。

思路：

1. 基数排序
2. 假设有数组[3,6,9,1,11,23,4,52,33]
3. 先找到最大值52, 52是个两位数，因此只要进行两轮排序
4. 第一轮，对于个位上的数排序

    ```
    | 个位上的数 | 元素集合 |
    | 0 | 
    | 1 | 1, 11 
    | 2 | 52 
    | 3 | 3, 23, 33 
    | 4 | 4 
    | 5 | 
    | 6 | 6 
    | 7 | 
    | 8 | 
    | 9 | 9 
    ```
    因此，第一轮之后元素的顺序为：[1, 11, 52, 3, 23, 33, 4, 6, 9]

5. 第二轮，对于十位上的数排序

    ```
    | 十位上的数 | 元素集合 |
    | 0 | 1, 3, 4, 6, 9 
    | 1 | 11 
    | 2 | 23 
    | 3 | 33 
    | 4 | 
    | 5 | 52 
    | 6 | 
    | 7 | 
    | 8 | 
    | 9 | 

    因此，第二轮之后元素的顺序为：[1, 3, 4, 6, 9, 11, 23, 33, 52]
    ```

最终代码：

```go
func bsort(nums []int) {
    n := len(nums)
    tmp := make([]int, n)
    maxVal := max(nums...)
    for round := 1; round <= maxVal; round *= 10 {
        cnt := [10]int{} // 
        for _, num := range nums {
            digit := num / round % 10
            cnt[digit]++
        }

        for i := 1; i < 10; i++ {
            cnt[i] += cnt[i-1]
        }

        // 从后往前放置所有的数，（从后往前是因为同一个位上可能有多个数）
        for i := n - 1; i >= 0; i-- {
            digit := nums[i] / round % 10
            tmp[cnt[digit]-1] = nums[i]
            cnt[digit]--
        }
        copy(nums, tmp)
    }
} 

func maximumGap(nums []int) (ans int) {
    n := len(nums)
    if n < 2 {
        return
    }

    bsort(nums)

    for i := 1; i < n; i++ {
        ans = max(ans, nums[i]-nums[i-1])
    }
    return
}

func max(a ...int) int {
    res := a[0]
    for _, v := range a[1:] {
        if v > res {
            res = v
        }
    }
    return res
}
```

### 907. 子数组的最小值之和

[907. 子数组的最小值之和](https://leetcode-cn.com/problems/sum-of-subarray-minimums/)
给定一个整数数组 arr，找到 min(b) 的总和，其中 b 的范围为 arr 的每个（连续）子数组。

由于答案可能很大，因此 返回答案模 10^9 + 7 。

思路：对于每一个nums[i], 分别向左右找到它的影响范围

```go
func sumSubarrayMins(arr []int) int {
    n := len(arr)
    mod := 1000000007
    ans := 0
    for i := 0; i < n; i++ {
        l := i - 1
        // 找到以arr[i]最为最小值的左边界
        for l >= 0 && arr[i] < arr[l] {
            l-- 
        }
        
        r := i + 1
        for r < n && arr[i] <= arr[r] {
            r++
        }

        // 左边的个数*右边的个数能得到子数组的数量，*a[i]表示加上多少个a[i]
        ans += (i - l) * (r - i) * arr[i]
    }

    return ans % mod
}
```

### 26. 删除有序数组中的重复项

[26. 删除有序数组中的重复项](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-array/)

给你一个 升序排列 的数组 nums ，请你 原地 删除重复出现的元素，使每个元素 只出现一次 ，返回删除后数组的新长度。元素的 相对顺序 应该保持 一致 。

由于在某些语言中不能改变数组的长度，所以必须将结果放在数组nums的第一部分。更规范地说，如果在删除重复项之后有 k 个元素，那么 nums 的前 k 个元素应该保存最终结果。

将最终结果插入 nums 的前 k 个位置后返回 k 。
不要使用额外的空间，你必须在 原地 修改输入数组 并在使用 O(1) 额外空间的条件下完成。

通用解法：

```go
func removeDuplicates(nums []int) int {
    // 移除重复项的通用函数
    replace := func(k int) int {
        // 下一个要被覆盖的位置
        replaceIdx := 0
        for _, num := range nums {
            // replaceIdx < k 意味着直接跳过前k个
            if replaceIdx < k || num != nums[replaceIdx-k] {
                nums[replaceIdx] = num
                replaceIdx++
            }
        }
        return replaceIdx
    }

    return replace(1)
}
```

### 80. 删除有序数组中的重复项 II

[80. 删除有序数组中的重复项 II](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-array-ii/)

给你一个有序数组 nums ，请你 原地 删除重复出现的元素，使每个元素 最多出现两次 ，返回删除后数组的新长度。

不要使用额外的数组空间，你必须在 原地 修改输入数组 并在使用 O(1) 额外空间的条件下完成。

通用解法：

```go
func removeDuplicates(nums []int) int {
    // 移除重复项的通用函数
    replace := func(k int) int {
        // 下一个要被覆盖的位置
        replaceIdx := 0
        for _, num := range nums {
            // replaceIdx < k 意味着直接跳过前k个
            if replaceIdx < k || num != nums[replaceIdx-k] {
                nums[replaceIdx] = num
                replaceIdx++
            }
        }
        return replaceIdx
    }

    return replace(2)
}
```

### 48. 旋转图像

[48. 旋转图像](https://leetcode-cn.com/problems/rotate-image/)

给定一个 n × n 的二维矩阵 matrix 表示一个图像。请你将图像顺时针旋转 90 度。

你必须在 原地 旋转图像，这意味着你需要直接修改输入的二维矩阵。请不要 使用另一个矩阵来旋转图像。

```go
func rotate(matrix [][]int)  {
    n := len(matrix)

    // 每次元素交换都会涉及到n^2/4个元素，所以循环时i，j不需要完整遍历
    for i := 0; i < n/2; i++ {
        for j := 0; j < (n + 1) / 2; j++ {
            temp := matrix[i][j]
            matrix[i][j] = matrix[n-j-1][i]
            matrix[n-j-1][i] = matrix[n-i-1][n-j-1]
            matrix[n-i-1][n-j-1] = matrix[j][n-i-1]
            matrix[j][n-i-1] = temp
        }
    }
}
```