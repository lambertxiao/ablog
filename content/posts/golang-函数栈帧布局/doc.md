---
author: "Lambert Xiao"
title: "Golang-函数栈帧布局"
date: "2022-03-11"
summary: "学会golang函数栈帧布局让你团灭各种defer面试题"
tags: ["golang"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
cover:
  image: "/cover/golang-函数栈帧布局.png"
---

## 栈帧布局

我们按照编程语言的语法定义的函数，会被编译器编译为一堆堆的机器指令，当程序运行时，可执行文件被加载到内存，这些机器指令对应到虚拟地址空间中的代码段

![](../1.png)

如图里的两个函数A和B，都会分布在代码段上。函数在执行时需要有足够的内存空间，供它存放局部变量，参数，返回值等数据，这段空间对应到虚拟地址空间里的栈。

栈从高地址往低地址扩展，栈底称为栈基BP，栈顶又称为栈指针SP，GO语言中函数栈帧布局如图

![](../2.png)

函数栈帧里一次存放着 `调用者的BP`, `局部变量`，`返回值`，`参数`。

![](../3.png)

当在函数A中调用函数B时，操作系统会调用 `call` 指令，`call`指令只做了两件事情：

1. 将下一条指令的地址入栈，也就是返回地址入栈，被调用函数执行结束后会返回到这里
2. 跳转到被调用函数的入口处执行，即通过将被调用函数的入口地址设置给PC或IP寄存器

调用里call指令之后，函数栈帧变成里下面这样

![](../4.png)

可以看出，每个函数的栈帧都是一样的结构

当函数执行完时，会释放自己的栈帧，同时ret指令会被调用，它的作用也有两个

1. 弹出call指令压如的返回地址
2. 跳转到这个返回地址

## 团灭defer

有了上面的知识储备，现在来看几个例子

### 例子1

```go
func main() {
    a, b := 1, 2
    swap(a, b)
}

func swap(a, b int) {
    a, b = b, a
}
```

有经验的我们一定马上就知道，这次swap并没有成功，我们在栈帧层面上看看是哪里出的问题

```
| ...                      |
| main-局部变量：a = 1       | # main函数BP
| main-局部变量：b = 2       |
| main-给swap的参数: b = 2   | # 这里给swap的a和b都是值拷贝
| main-给swap参数:   a = 1   |
| main-swap的返回地址         |
| main-BP                   |
| ...                       | # 这里开始进入swap函数的栈帧
```

> 注意上面main函数和swap都没有返回值，所以栈帧上也不需要分配返回值。参数入栈从右到左

进入swap函数后，swap将main给它的参数交换了，但实际上并没有改动到main里的局部变量

```
| ...                      |
| main-局部变量：a = 1       | # main函数里的局部变量不会改动
| main-局部变量：b = 2       |  
| main-给swap的参数: b = 1   | # b和a交换了
| main-给swap参数:   a = 2   |
| main-swap的返回地址         |
| main-BP                   |
| ...                       | # 这里开始进入swap函数的栈帧
```

### 例子2

```go
func main() {
    a, b := 1, 2
    swap(&a, &b)
}

func swap(a, b *int) {
    *a, *b = *b, *a
}
```


```
| ...                      |
| main-局部变量：a = 1       | # main函数BP
| main-局部变量：b = 2       |
| main-给swap的参数: addrB   | # addrA指向a，addrB指向B
| main-给swap参数:   addrA    |
| main-swap的返回地址         |
| main-BP                   |
| ...                       | # 这里开始进入swap函数的栈帧
```

交换之后

```
| ...                      |
| main-局部变量：a = 2       | # addrA和addrB指向的数据交换了
| main-局部变量：b = 1       |
| main-给swap的参数: addrB   | 
| main-给swap参数:   addrA   |
| main-swap的返回地址         |
| main-BP                   |
| ...                       | # 这里开始进入swap函数的栈帧
```

### 例子3

带匿名返回值的例子

```go
func main() {
    var a, b int
    b = incr(a)
}

func incr(a int) int {
    var b int

    defer func() {
        a++
        b++
    }()

    a++
    b = a
    return b
}
```

初始时的栈帧

```
| ...                      |
| main-局部变量：a = 0       | # main函数BP
| main-局部变量：b = 0       |
| main-incr的返回值：0       |
| main-给incr的参数: a = 0   | 
| main-incr的返回地址         |
| main-BP                   |
| incr-局部变量: b = 0       |
| ...                       | 
```

执行了 `a++` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：0       |
| main-给incr的参数: a = 1   | 这里增加了1
| main-incr的返回地址         |
| main-BP                   |
| incr-局部变量: b = 0       |
| ...                       | 
```

执行了 `b = a` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：0       |
| main-给incr的参数: a = 1   | 
| main-incr的返回地址         |
| main-BP                   |
| incr-局部变量: b = 1       | 这里变了
| ...                       | 
```

执行 `return b` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：1       | 这里变了
| main-给incr的参数: a = 1   | 
| main-incr的返回地址         |
| main-BP                   |
| incr-局部变量: b = 1       | 
| ...                       | 
```

在defer里执行 `a++` 和 `b++` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：1       | 
| main-给incr的参数: a = 2   | 这里加1
| main-incr的返回地址         |
| main-BP                   |
| incr-局部变量: b = 2       |  这里加1
| ...                       | 
```

incr的返回值赋给b之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 1       |
| main-incr的返回值：1       | 
| main-给incr的参数: a = 2   | 这里加1
| main-incr的返回地址         |
| main-BP                   |
| incr-局部变量: b = 2       |  这里加1
| ...                       | 
```

因此最后的结果是a为0，b为1


### 例子4

带命名返回值的例子

```go
func main() {
    var a, b int
    b = incr(a)
}

func incr(a int) (b int) {
    defer func() {
        a++
        b++
    }()

    a++
    return a
}
```

初始时的栈帧，incr上没有局部变量b

```
| ...                      |
| main-局部变量：a = 0       | # main函数BP
| main-局部变量：b = 0       |
| main-incr的返回值：0       |
| main-给incr的参数: a = 0   | 
| main-incr的返回地址         |
| main-BP                   |
| ...                       | 
```

执行了 `a++` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：0       |
| main-给incr的参数: a = 1   | # 这里变了
| main-incr的返回地址         |
| main-BP                   |
| ...                       | 
```

执行了 `return a` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：1       | # 这里变了
| main-给incr的参数: a = 1   | 
| main-incr的返回地址         |
| main-BP                   |
| ...                       | 
```

在defer里执行 `a++` 和 `b++` 之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 0       |
| main-incr的返回值：2       | # 这里变了
| main-给incr的参数: a = 2   | # 这里变了
| main-incr的返回地址         |
| main-BP                   |
| ...                       | 
```

incr的返回值赋给b之后

```
| ...                      |
| main-局部变量：a = 0       | 
| main-局部变量：b = 2       | # 这里变了
| main-incr的返回值：2       | 
| main-给incr的参数: a = 2   | 
| main-incr的返回地址         |
| main-BP                   |
| ...                       | 
```

因此最后的结果是a为0，b为2

## 总结

了解栈帧布局之后，对于复杂的defer调用，只要能画出函数栈帧情况，问题基本就迎刃而解了
