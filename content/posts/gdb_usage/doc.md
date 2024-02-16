---
author: "Lambert Xiao"
title: "使用GDB调试程序"
date: "2024-02-15"
summary: "好记性不如烂笔头"
tags: ["c++"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

<table>
  <tr>
    <td>命令类型</td>
    <td>命令</td>
    <td>功能</td>
  </tr>
  <tr>
    <td>启动/停止</td>
    <td>run</td>
    <td>启动程序</td>
  </tr>
  <tr>
    <td></td>
    <td>r</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>run 命令行参数</td>
    <td>以传入参数的方式启动程序</td>
  </tr>
  <tr>
    <td></td>
    <td>run &gt; 输出文件</td>
    <td>将输出重定向到输出文件</td>
  </tr>
  <tr>
    <td></td>
    <td>continue</td>
    <td>继续运行，直到下一个断点</td>
  </tr>
  <tr>
    <td></td>
    <td>c</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>kill</td>
    <td>停止程序</td>
  </tr>
  <tr>
    <td></td>
    <td>quit</td>
    <td>退出gdb</td>
  </tr>
  <tr>
    <td>源代码</td>
    <td>list</td>
    <td>查看源代码</td>
  </tr>
  <tr>
    <td></td>
    <td>l</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>list 行号</td>
    <td>显示指定行号代码</td>
  </tr>
  <tr>
    <td></td>
    <td>list 函数名</td>
    <td>显示指定函数的代码</td>
  </tr>
  <tr>
    <td></td>
    <td>list -</td>
    <td>往前显示代码</td>
  </tr>
  <tr>
    <td></td>
    <td>list 开始, 结束</td>
    <td>显示指定区间的代码</td>
  </tr>
  <tr>
    <td></td>
    <td>list 文件名:行号</td>
    <td>显示指定文件名的指定行代码</td>
  </tr>
  <tr>
    <td></td>
    <td>set listsize 数字</td>
    <td>设置显示的代码行数</td>
  </tr>
  <tr>
    <td></td>
    <td>show listsize</td>
    <td>查看一次显示的代码行数</td>
  </tr>
  <tr>
    <td></td>
    <td>directory 目录名</td>
    <td>添加目录到源代码搜索路径中</td>
  </tr>
  <tr>
    <td></td>
    <td>dir 目录名</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>show directories</td>
    <td>查看源代码搜索目录</td>
  </tr>
  <tr>
    <td></td>
    <td>directory</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>dir</td>
    <td>清空添加到源代码搜索目录中的目录</td>
  </tr>
  <tr>
    <td>断点管理</td>
    <td>break</td>
    <td>断点命令</td>
  </tr>
  <tr>
    <td></td>
    <td>b</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>break 函数名</td>
    <td>为函数设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break 代码行号</td>
    <td>在某一代码行上设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break 类名:函数名</td>
    <td>在某个类的函数上设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break 文件名:函数名</td>
    <td>在文件名指定的函数上设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break 文件名:行号</td>
    <td>在文件名指定的代码行上设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break *地址</td>
    <td>在指定地址设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break +偏移量</td>
    <td>在当前代码行加上偏移量的位置设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break -偏移量</td>
    <td>在当前代码行减去偏移量的位置设置断点</td>
  </tr>
  <tr>
    <td></td>
    <td>break 行号 if条件</td>
    <td>设置条件断点</td>
  </tr>
  <tr>
    <td></td>
    <td>tbreak</td>
    <td>设置临时断点</td>
  </tr>
  <tr>
    <td></td>
    <td>watch 表达式</td>
    <td>添加观察点</td>
  </tr>
  <tr>
    <td></td>
    <td>clear</td>
    <td>删除所有断点</td>
  </tr>
  <tr>
    <td></td>
    <td>clear 函数</td>
    <td>删除该函数的断点</td>
  </tr>
  <tr>
    <td></td>
    <td>clear 行号</td>
    <td>删除行号对应的断点</td>
  </tr>
  <tr>
    <td></td>
    <td>delete</td>
    <td>删除所有断点，包括观察点和捕获点</td>
  </tr>
  <tr>
    <td></td>
    <td>d</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>delete 断点编号</td>
    <td>删除指定编号断点</td>
  </tr>
  <tr>
    <td></td>
    <td>delete 断点范围</td>
    <td>删除指定范围断点</td>
  </tr>
  <tr>
    <td></td>
    <td>disable 断点范围</td>
    <td>禁用指定范围的断点</td>
  </tr>
  <tr>
    <td></td>
    <td>enable 断点范围</td>
    <td>启用指定范围断点</td>
  </tr>
  <tr>
    <td></td>
    <td>enable 断点编号 once</td>
    <td>启用指定断点一次</td>
  </tr>
  <tr>
    <td>执行</td>
    <td>continue 数量</td>
    <td>继续执行，忽略指定数量的命中次数</td>
  </tr>
  <tr>
    <td></td>
    <td>finish</td>
    <td>跳出当前函数</td>
  </tr>
  <tr>
    <td></td>
    <td>step</td>
    <td>逐语句执行</td>
  </tr>
  <tr>
    <td></td>
    <td>s</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>step 步数</td>
    <td>逐语句执行步数</td>
  </tr>
  <tr>
    <td></td>
    <td>next</td>
    <td>逐过程执行</td>
  </tr>
  <tr>
    <td></td>
    <td>n</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>next 数量</td>
    <td>逐过程执行指定行数的代码</td>
  </tr>
  <tr>
    <td></td>
    <td>where</td>
    <td>显示当前执行的具体函数和代码行</td>
  </tr>
  <tr>
    <td>调用栈</td>
    <td>backtrace</td>
    <td>显示调用栈信息</td>
  </tr>
  <tr>
    <td></td>
    <td>bt</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>bt 栈帧数</td>
    <td>显示指定数量的栈帧（从小到大）</td>
  </tr>
  <tr>
    <td></td>
    <td>bt -栈帧数</td>
    <td>显示指定数量的栈帧（从大到小）</td>
  </tr>
  <tr>
    <td></td>
    <td>backtrace full</td>
    <td>显示所有栈帧的局部变量</td>
  </tr>
  <tr>
    <td></td>
    <td>frame</td>
    <td>显示当前帧</td>
  </tr>
  <tr>
    <td></td>
    <td>frame 帧编号</td>
    <td>切换帧到指定编号的帧</td>
  </tr>
  <tr>
    <td></td>
    <td>f 帧编号</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>up</td>
    <td>切换帧，将当前帧增大1</td>
  </tr>
  <tr>
    <td></td>
    <td>down</td>
    <td>切换帧，将当前帧减少1</td>
  </tr>
  <tr>
    <td></td>
    <td>up 帧数量</td>
    <td>切换帧，将当前帧增大指定数量切换帧，将当前帧减少指定数量</td>
  </tr>
  <tr>
    <td></td>
    <td>down 帧数量</td>
    <td></td>
  </tr>
  <tr>
    <td>查看信息</td>
    <td>info frame</td>
    <td>查看当前帧的信息</td>
  </tr>
  <tr>
    <td></td>
    <td>info args </td>
    <td>查看当前帧的参数</td>
  </tr>
  <tr>
    <td></td>
    <td>info locals</td>
    <td>查看当前帧的局部变量</td>
  </tr>
  <tr>
    <td></td>
    <td>info breakpoints</td>
    <td>查看所有断点信息</td>
  </tr>
  <tr>
    <td></td>
    <td>info break </td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>i b</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>info break 断点编号</td>
    <td>查看指定断点编号的断点信息</td>
  </tr>
  <tr>
    <td></td>
    <td>info watchpoints</td>
    <td>查看所有观察点信息</td>
  </tr>
  <tr>
    <td></td>
    <td>info registers</td>
    <td>查看所有整型寄存器信息</td>
  </tr>
  <tr>
    <td></td>
    <td>info threads</td>
    <td>查看所有线程信息</td>
  </tr>
  <tr>
    <td>查看变量</td>
    <td>x 地址</td>
    <td>查看指定地址的内存</td>
  </tr>
  <tr>
    <td></td>
    <td>x /nfu 地址</td>
    <td>以格式化的方式查看指定地址的内存</td>
  </tr>
  <tr>
    <td></td>
    <td>print 变量名</td>
    <td>查看变量</td>
  </tr>
  <tr>
    <td></td>
    <td>p 变量名</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>p 文件名::变量名</td>
    <td>查看指定文件的变量</td>
  </tr>
  <tr>
    <td></td>
    <td>ptype 变量</td>
    <td>查看变量类型</td>
  </tr>
  <tr>
    <td></td>
    <td>ptype 数据类型</td>
    <td>查看类型详细信息</td>
  </tr>
  <tr>
    <td>gdb模式</td>
    <td>set logging on </td>
    <td>设置日志开关</td>
  </tr>
  <tr>
    <td></td>
    <td>set logging off </td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>show logging</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>set logging file 日志文件</td>
    <td>设置日志文件名，默认名称为gdb.txt</td>
  </tr>
  <tr>
    <td></td>
    <td>set print array on </td>
    <td>数组显示是否友好开关，默认是关闭的</td>
  </tr>
  <tr>
    <td></td>
    <td>set print array off</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>show print array</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>set print array-indexes on</td>
    <td>显示数组索引开关，默认是关闭的</td>
  </tr>
  <tr>
    <td></td>
    <td>set print array-indexes off </td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>show print array-indexes</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>set print pretty on </td>
    <td>格式化结构体，默认是关闭的</td>
  </tr>
  <tr>
    <td></td>
    <td>set print pretty off </td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>show print pretty</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>set print union on </td>
    <td>联合体开关，默认是关闭的</td>
  </tr>
  <tr>
    <td></td>
    <td>set print union off </td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>show print union</td>
  </tr>
</table>
