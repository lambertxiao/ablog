---
author: "Lambert Xiao"
title: "加密算法之ECDH"
date: "2022-03-06"
summary: ""
tags: ["加密", "网络知识"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# ECDH算法

ECDH全称是椭圆曲线迪菲-赫尔曼秘钥交换（Elliptic Curve Diffie–Hellman key Exchange），主要是用来在一个不安全的通道中建立起安全的共有加密资料，一般来说交换的都是私钥，这个密钥一般作为“对称加密”的密钥而被双方在后续数据传输中使用。

## 算法流程

我们通过一个经典的场景，Alice和Bob要在一条不安全的线路上交换秘钥，交换的秘钥不能被中间人知晓。
首先，双方约定使用ECDH秘钥交换算法，这个时候双方也知道了ECDH算法里的一个大素数P，这个P可以看做是一个算法中的常量。
P的位数决定了攻击者破解的难度。还有一个整数g用来辅助整个秘钥交换，g不用很大，一般是2或者5，双方知道g和p之后就开始了ECDH交换秘钥的过程了。

1. Alice生成一个整数a作为私钥，需要利用p，g，a通过公式 `g^a mod p = A` 生成A作为公钥传递。
2. Bob通过链路收到Alice发来的p，g，A，知道了Alice的公钥A。这个时候Bob也生成自己的私钥b，然后通过公式 `g^b mod p = B` 生成自己公钥B。
3. Alice收到Bob发来的公钥B以后，同样通过 `B^a mod p = K` 生成公共秘钥K，这样Alice和Bob就通过不传递私钥a和b完成了对公共秘钥K的协商。

## 举个栗子

我们通过代入具体的数字来重复一下上面的过程：

1. Alice和Bob同意使用质数p和整数g：
   p = 83, g = 8

Alice选择秘钥 a = 9, 生成公钥 g^a mod p = A 并发送
   (8^9) mod 83 = 5  

Bob选择秘钥 b = 21, 生成公钥 A^b mod p = K 并发送
   (8^21) mod 83 = 18

Alice计算 B^a mod p = K
   18^9 mod 83 = 24
  
Bob计算 B^a mod p = K
   5^21 mod 83 = 24
  
至此24就是双方协商出来的秘钥。

## 存在的问题

ECDH并不验证公钥发送者的身份，所以无法阻止中间人攻击，需要使用CA机构向双方提供可信的数字签名密钥
