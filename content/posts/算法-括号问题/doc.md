---
author: "Lambert Xiao"
title: "算法-括号问题"
date: "2022-03-13"
summary: ""
tags: ["算法"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

[20. 有效的括号](https://leetcode-cn.com/problems/valid-parentheses/)

给定一个只包括 '('，')'，'{'，'}'，'['，']' 的字符串 s ，判断字符串是否有效。

有效字符串需满足：
左括号必须用相同类型的右括号闭合。
左括号必须以正确的顺序闭合。

```ts
function isValid(s: string): boolean {
    let stack = []
    for (let c of s) {
        if (c == '(' || c == '{' || c == '[') {
            stack.push(c)
        }

        if (c == ')' || c == '}' || c == ']') {
            let e = stack.pop()
            if (c != rightof(e)) {
                return false
            }
        }
    }

    if (stack.length > 0) {
        return false
    }

    return true
};

function rightof(c: string): string {
    if (c == "{") {
        return "}"
    }

    if (c == "[") {
        return "]"
    }

    if (c == "(") {
        return ")"
    }

    return ""
}
```