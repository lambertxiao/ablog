---
author: "Lambert Xiao"
title: "openssl生成自签名证书"
date: "2023-04-20"
summary: ""
tags: [""]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

工作中用到了，由于需要签入指定的域名，折腾了一番，写篇文章记录一下

## 生成证书的配置文件

创建`openssl.conf`，填入下面内容

```conf
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
countryName = country
stateOrProvinceName = province
localityName = city
organizationName = company name
commonName = domain name or ip

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1=test.com
DNS.2=www.test.com
```

## 生成私钥文件

```
openssl genrsa -out test.key 2048
```

## 生成证书的request文件

```
openssl req -new -key test.key -out test.csr -config openssl.conf -subj '/C=CN/ST=BeiJing/L=BeiJing/O=test.com/OU=test/CN=test/emailAddress=test@qq.com'
```

## 查看生成的request文件

```
openssl req -in test.csr -text -noout
```

## 生成证书文件

```
openssl x509 -req -days 3650 -sha1 -in test.csr -signkey test.key -out test.crt -CAcreateserial -extensions v3_req -extfile ./openssl.conf
```

## 查看生成的证书

```
openssl x509  -in test.crt -text -noout
```
