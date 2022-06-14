---
author: "Lambert Xiao"
title: "CMake和Automake"
date: "2022-03-06"
summary: "在C和C++的开源项目里没少见他俩"
tags: ["cmake", "automake"]
categories: [""]
series: ["Themes Guide"]
ShowToc: true
TocOpen: true
---

## 简介

cmake和automake本质上都是用来生成Makefile的工具，为啥Makefile需要工具来生成呢？因为大型的C和C++项目构建步骤特别繁琐，自己维护Makefile特别麻烦，因此懒惰的程序员们开发了各种生成Makefile的工具，cmake和automake就是这样的工具。

## automake使用

1. 运行autoscan命令
2. 将configure.scan 文件重命名为configure.in，并修改configure.in文件
3. 在project目录下新建Makefile.am文件，并在core和shell目录下也新建makefile.am文件
4. 在project目录下新建NEWS、 README、 ChangeLog 、AUTHORS文件
5. 将/usr/share/automake-1.X/目录下的depcomp和complie文件拷贝到本目录下
6. 运行aclocal命令
7. 运行autoconf命令
8. 运行automake -a命令
9. 运行./confiugre脚本(常见的开源软件基本已经提前生成好了configure文件了)

## cmake使用

使用cmake仅需要提供一份CMakeLists.txt, 然后运行cmake命令，即可得到一份Makefile文件。

## 功能对比

<table>
<tr>
  <td>命令</td>
  <td>automake</td>
  <td>cmake</td>
</tr>
<tr>
  <td>变量定义</td>
  <td>name=...</td>
  <td>set(name, "...")</td>
</tr>
<tr>
  <td>环境检测</td>
  <td>
    <table>
      <tr><td>AC_INIT</td></tr>
      <tr><td>AC_PROG_CC</td></tr>
      <tr><td>AC_CHECK_LIB([pthread], [pthread_rwlock_init])</td></tr>
      <tr><td>AC_PROG_RANLIB</td></tr>
      <tr><td>AC_OUTPUT</td></tr>
    </table>
  </td>
  <td>
    <table>
      <tr><td>find_library(lib libname pathllist)</td></tr>
      <tr><td>find_package(packename)</td></tr>
      <tr><td>find_path(var name pathlist)</td></tr>
      <tr><td>find_program(var name pathlist)</td></tr>
    </table>
  </td>
</tr>
<tr>
  <td>子目录</td>
  <td>SUBDIRS=</td>
  <td>add_subdirectory(list)</td>
</tr>
<tr>
  <td>可执行文件</td>
  <td>
    <table>
      <tr><td>bin_PROGRAMS=binname</td></tr>
      <tr><td>binname_SOURCES=</td></tr>
      <tr><td>binname_LDADD=</td></tr>
      <tr><td>binname_CFLAGS=</td></tr>
      <tr><td>binname_LDFLAGS=</td></tr>
    </table>
  </td>
  <td>
    <table>
      <tr><td>add_executable(binname ${sources})</td></tr>
      <tr><td>target_link_libraries(binname librarylist)</td></tr>
    </table>
  </td>
</tr>
<tr>
  <td>动态库</td>
  <td>
    <table>
      <tr><td>lib_LIBRARIES=libname.so</td></tr>
      <tr><td>libname_SOURCES=</td></tr>
    </table>
  </td>
  <td>
    add_library(libname shared ${source})
  </td>
</tr>
<tr>
  <td>静态库</td>
  <td>
    <table>
      <tr><td>lib_LIBRARIES=libname.a</td></tr>
      <tr><td>ibname_a_SOURCES=</td></tr>
    </table>
  </td>
  <td>
    add_library(libname static ${source})
  </td>
</tr>
<tr>
  <td>头文件</td>
  <td>
    <table>
      <tr><td>INCLUDES=</td></tr>
      <tr><td>include_HEADES=或CFLAGS=-I</td></tr>
    </table>
  </td>
  <td>
    include_directories(list)
  </td>
</tr>
<tr>
  <td>源码搜索</td>
  <td></td>
  <td>
    aux_source_directories(. list)
  </td>
</tr>
<tr>
  <td>依赖库</td>
  <td>LIBS= 或 LDADD=</td>
  <td>
    target_link_libraries(binname librarylist)
  </td>
</tr>
<tr>
  <td>标志</td>
  <td>CFLAGS= 或 LDFLAGS=</td>
  <td>
    set(CMAKE_C_FLAGS  ...)
  </td>
</tr>
<tr>
  <td>libtool</td>
  <td>
    <table>
      <tr><td>AC_PROG_LIBTOOL</td></tr>
      <tr><td>lib_LTLIBRARIES=name.la</td></tr>
      <tr><td>name_la_SOURCES=</td></tr>
    </table>
  </td>
  <td></td>
</tr>
<tr>
  <td>条件语句</td>
  <td>使用Make的条件语句 if() endif</td>
  <td>if(my), else(my), endif(my), while(condition), endwhile(condition)</td>
</tr>
<tr>
  <td>执行外部命令</td>
  <td></td>
  <td>exec_program(commd )</td>
</tr>
<tr>
  <td>子模块</td>
  <td></td>
  <td>include()</td>
</tr>
<tr>
  <td>信息输出</td>
  <td></td>
  <td>messge(STATUS "messge")</td>
</tr>
<tr>
  <td>项目</td>
  <td></td>
  <td>project(name)</td>
</tr>
<tr>
  <td>其他文件</td>
  <td>EXTRA_DIST</td>
  <td>install(FILES files.. ), install(DIRECTORY dirs..)</td>
</tr>
<tr>
  <td>安装设置</td>
  <td>EXTRA_DIST</td>
  <td>install</td>
</tr>
</table>
