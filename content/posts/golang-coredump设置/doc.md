---
author: "Lambert Xiao"
title: "Golang-Coredump设置"
date: "2022-06-014"
summary: "定位crash问题少不了"
tags: ["golang"]
categories: ["golang"]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## Golang-Coredump设置

---

当服务运行过程中异常crash时，我们通常需要借助操作系统生成的core文件来定位问题，core文件中会包含程序crash时的堆栈信息，而对于golang程序，设置coredump配置可分为下面几个步骤:

1. 设置ulimit

    `echo -e "\n* soft core unlimited\n" >> /etc/security/limits.conf`

2. 设置core文件输出目录

    `mkdir -p /data/corefiles && chmod 777 /data/corefiles`

3. 设置core_pattern

    `echo -e "\nkernel.core_pattern=/data/corefiles/core-%e-%s-%u-%g-%p-%t" >> /etc/sysctl.conf`

4. 使配置生效

    `sysctl -p /etc/sysctl.conf`

5. 在启动go应用前增加环境变量 `GOTRACEBACK=crash`

    ```bash
    export GOTRACEBACK=crash
    # 或
    GOTRACEBACK=crash ./your-app
    ```
