### main函数

> init/main.c

```c
// 下面三行分别将指定的线性地址强行转换为给定数据类型的指针，并获取指针所指
// 的内容。由于内核代码段被映射到从物理地址零开始的地方，因此这些线性地址
// 正好也是对应的物理地址。这些指定地址处内存值的含义请参见setup程序读取并保存的参数。
#define EXT_MEM_K (*(unsigned short *)0x90002) // 直接将内存地址转化为结构体指针
#define DRIVE_INFO (*(struct drive_info *)0x90080)
#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)

static long memory_end = 0;                     // 机器具有的物理内存容量（字节数）
static long buffer_memory_end = 0;              // 高速缓冲区末端地址
static long main_memory_start = 0;              // 主内存（将用于分页）开始的位置

int ROOT_DEV = 0;       // 根文件系统设备号。
struct drive_info { char dummy[32] } drive_info; // 用于存放硬盘参数表信息


// 内核初始化主程序。初始化结束后将以任务0（idle任务即空闲任务）的身份运行。
void main(void)        /* This really IS void, no error here. */
{          
    // 根设备号 ->ROOT_DEV；高速缓存末端地址->buffer_memory_end;
    // 机器内存数->memory_end；主内存开始地址->main_memory_start；
    // 其中ROOT_DEV已在前面包含进的fs.h文件中声明为extern int
    ROOT_DEV = ORIG_ROOT_DEV;
    drive_info = DRIVE_INFO;        // 复制0x90080处的硬盘参数
    memory_end = (1<<20) + (EXT_MEM_K<<10);     // 内存大小=1Mb + 扩展内存(k)*1024 byte
    memory_end &= 0xfffff000;                   // 忽略不到4kb(1页)的内存数

    if (memory_end > 16*1024*1024)              // 内存超过16Mb，则按16Mb计
        memory_end = 16*1024*1024;
    
    // 以下根据内存的大小决定缓冲区的大小
    if (memory_end > 12*1024*1024)              // 如果内存>12Mb,则设置缓冲区末端=4Mb 
        buffer_memory_end = 4*1024*1024;
    else if (memory_end > 6*1024*1024)          // 否则若内存>6Mb,则设置缓冲区末端=2Mb
        buffer_memory_end = 2*1024*1024;
    else
        buffer_memory_end = 1*1024*1024;        // 否则设置缓冲区末端=1Mb

    main_memory_start = buffer_memory_end;

    // 如果在Makefile文件中定义了内存虚拟盘符号RAMDISK,则初始化虚拟盘。此时主内存将减少。
#ifdef RAMDISK
    main_memory_start += rd_init(main_memory_start, RAMDISK*1024);
#endif

    // 以下是内核进行所有方面的初始化工作
    mem_init(main_memory_start,memory_end); // 主内存区初始化。mm/memory.c
    trap_init();                            // 陷阱门(硬件中断向量)初始化，kernel/traps.c
    blk_dev_init();                         // 块设备初始化,kernel/blk_drv/ll_rw_blk.c
    chr_dev_init();                         // 字符设备初始化, kernel/chr_drv/tty_io.c
    tty_init();                             // tty初始化， kernel/chr_drv/tty_io.c
    time_init();                            // 设置开机启动时间 startup_time
    sched_init();                           // 调度程序初始化(加载任务0的tr,ldtr)(kernel/sched.c)
    // 缓冲管理初始化，建内存链表等。(fs/buffer.c)
    buffer_init(buffer_memory_end);
    hd_init();                              // 硬盘初始化，kernel/blk_drv/hd.c
    floppy_init();                          // 软驱初始化，kernel/blk_drv/floppy.c
    sti();                                  // 所有初始化工作都做完了，开启中断
    // 下面过程通过在堆栈中设置的参数，利用中断返回指令启动任务0执行。
    move_to_user_mode();                    // 移到用户模式下执行
    if (!fork()) {        /* we count on this going ok */
        init();                             // 在新建的子进程(任务1)中执行。
    }

    // pause系统调用会把任务0转换成可中断等待状态，再执行调度函数。但是调度函数只要发现系统中
    // 没有其他任务可以运行是就会切换到任务0，而不依赖于任务0的状态。
    for(;;) pause();
}
```

