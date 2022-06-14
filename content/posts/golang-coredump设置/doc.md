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
## 查看coredump内容

### 使用go语言的dlv

dlv可用于调试go程序，也可用于core文件的诊断

安装

```bash
go install github.com/go-delve/delve/cmd/dlv@master
```

使用dlv打开core文件

```
dlv core <executable> <core> [flags]
```

进入dlv的终端后执行 `help`, 查看帮助

```bash
WARN[0000] CGO_CFLAGS already set, Cgo code could be optimized.  layer=dlv
Type 'help' for list of commands.
(dlv) help
The following commands are available:

Running the program:
    call ------------------------ Resumes process, injecting a function call (EXPERIMENTAL!!!)
    continue (alias: c) --------- Run until breakpoint or program termination.
    next (alias: n) ------------- Step over to next source line.
    rebuild --------------------- Rebuild the target executable and restarts it. It does not work if the executable was not built by delve.
    restart (alias: r) ---------- Restart process.
    rev ------------------------- Reverses the execution of the target program for the command specified.
    rewind (alias: rw) ---------- Run backwards until breakpoint or start of recorded history.
    step (alias: s) ------------- Single step through program.
    step-instruction (alias: si)  Single step a single cpu instruction.
    stepout (alias: so) --------- Step out of the current function.

Manipulating breakpoints:
    break (alias: b) ------- Sets a breakpoint.
    breakpoints (alias: bp)  Print out info for active breakpoints.
    clear ------------------ Deletes breakpoint.
    clearall --------------- Deletes multiple breakpoints.
    condition (alias: cond)  Set breakpoint condition.
    on --------------------- Executes a command when a breakpoint is hit.
    toggle ----------------- Toggles on or off a breakpoint.
    trace (alias: t) ------- Set tracepoint.
    watch ------------------ Set watchpoint.

Viewing program variables and memory:
    args ----------------- Print function arguments.
    display -------------- Print value of an expression every time the program stops.
    examinemem (alias: x)  Examine raw memory at the given address.
    locals --------------- Print local variables.
    print (alias: p) ----- Evaluate an expression.
    regs ----------------- Print contents of CPU registers.
    set ------------------ Changes the value of a variable.
    vars ----------------- Print package variables.
    whatis --------------- Prints type of an expression.

Listing and switching between threads and goroutines:
    goroutine (alias: gr) -- Shows or changes current goroutine
    goroutines (alias: grs)  List program goroutines.
    thread (alias: tr) ----- Switch to the specified thread.
    threads ---------------- Print out info for every traced thread.

Viewing the call stack and selecting frames:
    deferred --------- Executes command in the context of a deferred call.
    down ------------- Move the current frame down.
    frame ------------ Set the current frame, or execute command on a different frame.
    stack (alias: bt)  Print stack trace.
    up --------------- Move the current frame up.

Other commands:
    check (alias: checkpoint) ----------- Creates a checkpoint at the current position.
    checkpoints ------------------------- Print out info for existing checkpoints.
    clear-checkpoint (alias: clearcheck)  Deletes checkpoint.
    config ------------------------------ Changes configuration parameters.
    disassemble (alias: disass) --------- Disassembler.
    dump -------------------------------- Creates a core dump from the current process state
    edit (alias: ed) -------------------- Open where you are in $DELVE_EDITOR or $EDITOR
    exit (alias: quit | q) -------------- Exit the debugger.
    funcs ------------------------------- Print list of functions.
    help (alias: h) --------------------- Prints the help message.
    libraries --------------------------- List loaded dynamic libraries
    list (alias: ls | l) ---------------- Show source code.
    source ------------------------------ Executes a file containing a list of delve commands
    sources ----------------------------- Print list of source files.
    transcript -------------------------- Appends command output to a file.
    types ------------------------------- Print list of types

Type help followed by a command for full documentation.
(dlv)
```

通过`stack`命令可知发生crash时的堆栈信息

```
(dlv) stack
 0  0x0000000000472f21 in runtime.raise
    at /usr/local/go/src/runtime/sys_linux_amd64.s:164
 1  0x000000000044f67d in runtime.dieFromSignal
    at /usr/local/go/src/runtime/signal_unix.go:768
 2  0x000000000044fcd1 in runtime.sigfwdgo
    at /usr/local/go/src/runtime/signal_unix.go:982
 3  0x000000000044e4f4 in runtime.sigtrampgo
    at /usr/local/go/src/runtime/signal_unix.go:416
 4  0x00000000004732a3 in runtime.sigtramp
    at /usr/local/go/src/runtime/sys_linux_amd64.s:399
 5  0x00000000004733a0 in runtime.sigreturn
    at /usr/local/go/src/runtime/sys_linux_amd64.s:493
 6  0x000000000043800c in runtime.crash
    at /usr/local/go/src/runtime/signal_unix.go:860
 7  0x000000000043800c in runtime.fatalpanic
    at /usr/local/go/src/runtime/panic.go:1217
 8  0x0000000000437945 in runtime.gopanic
    at /usr/local/go/src/runtime/panic.go:1065
 9  0x000000000080eca5 in git.ucloudadmin.com/epoch/us3fs/internal.(*US3fsX).ReadFile
    at /Users/lambert.xiao/workspace/us3fs/internal/fuse_high.go:286
10  0x00000000007f0004 in git.ucloudadmin.com/epoch/go-fuse/fuseutil.(*fileSystemServer).handleOp
    at /Users/lambert.xiao/gopath/pkg/mod/git.ucloudadmin.com/epoch/go-fuse@v0.0.3/fuseutil/file_system.go:183
11  0x00000000004716e1 in runtime.goexit
    at /usr/local/go/src/runtime/asm_amd64.s:1371
(dlv)
```

### 使用gdb

gdb虽然也可以用于core文件的查看，但go官方并不推荐使用gdb，详情参考：`https://go.dev/doc/gdb`
