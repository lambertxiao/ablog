---
author: "Lambert Xiao"
title: "DNS记录都有哪些？"
date: "2022-03-06"
summary: "NS记录、A记录都是些啥"
tags: ["网络知识"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

# Dns解析

- NS记录

    用来指定域名由哪个 DNS 服务器进行解析

- A记录

    用来指定主机名对应的 IPv4 地址

- AAAA记录

    用来指定主机名对应的 IPv6 地址

- CNAME

    用来定义域名的别名，方便实现将多个域名解析到同一个IP地址

- PTR记录

    常用于反向地址解析，将 IP 地址解析到对应的名称

- SOA记录

    SOA记录用于在多台NS记录中哪一台是主DNS服务器
