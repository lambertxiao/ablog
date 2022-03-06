### 设置主存区域的mem_init函数

> mm/memory.c

```c
// 物理内存管理初始化
// 该函数对1MB以上的内存区域以页面为单位进行管理前的初始化设置工作。一个页面长度
// 为4KB bytes.该函数把1MB以上所有物理内存划分成一个个页面，并使用一个页面映射字节
// 数组mem_map[]来管理所有这些页面。对于具有16MB内存容量的机器，该数组共有3840
// 项((16MB-1MB)/4KB)，即可管理3840个物理页面。每当一个物理内存页面被占用时就把
// mem_map[]中对应的字节值增1；若释放一个物理页面，就把对应字节值减1。若字节值为0，
// 则表示对应页面空闲；若字节值大于或等于1，则表示对应页面被占用或被不同程序共享占用。
// 在该版本的Linux内核中，最多能管理16MB的物理内存，大于16MB的内存将弃之不用。
// 对于具有16MB内存的PC机系统，在没有设置虚拟盘RAMDISK的情况下start_mem通常是4MB，
// end_mem是16MB。因此此时主内存区范围是4MB-16MB,共有3072个物理页面可供分配。而
// 范围0-1MB内存空间用于内核系统（其实内核只使用0-640Kb，剩下的部分被部分高速缓冲和
// 设备内存占用）。
// 参数start_mem是可用做页面分配的主内存区起始地址（已去除RANDISK所占内存空间）。
// end_mem是实际物理内存最大地址。而地址范围start_mem到end_mem是主内存区。

static long HIGH_MEMORY = 0;            // 全局变量，存放实际物理内存最高端地址

// linux0.11内核默认支持的最大内存容量是16MB，可以修改这些定义适合更多的内存。
// 内存低端(1MB)
#define LOW_MEM 0x100000
// 分页内存15 MB，主内存区最多15M.
#define PAGING_MEMORY (15*1024*1024)
// 分页后的物理内存页面数（3840）
#define PAGING_PAGES (PAGING_MEMORY>>12)
// 指定地址映射为页号
#define MAP_NR(addr) (((addr)-LOW_MEM)>>12)
// 页面被占用标志.
#define USED 100

static unsigned char mem_map [ PAGING_PAGES ] = {0,};

void mem_init(long start_mem, long end_mem)
{
	int i;

    // 首先将1MB到16MB范围内所有内存页面对应的内存映射字节数组项置为已占用状态，
    // 即各项字节全部设置成USED(100)。PAGING_PAGES被定义为(PAGING_MEMORY>>12)，
    // 即1MB以上所有物理内存分页后的内存页面数(15MB/4KB = 3840).
	HIGH_MEMORY = end_mem;                  // 设置内存最高端(16MB)
	for (i=0 ; i<PAGING_PAGES ; i++)
		mem_map[i] = USED;
    // 然后计算主内存区起始内存start_mem处页面对应内存映射字节数组中项号i和主内存区页面数。
    // 此时mem_map[]数组的第i项正对应主内存区中第1个页面。最后将主内存区中页面对应的数组项
    // 清零(表示空闲)。对于具有16MB物理内存的系统，mem_map[]中对应4MB-16MB主内存区的项被清零。
	i = MAP_NR(start_mem);      // 主内存区其实位置处页面号
	end_mem -= start_mem;
	end_mem >>= 12;             // 主内存区中的总页面数
	while (end_mem-->0)
		mem_map[i++]=0;         // 主内存区页面对应字节值清零
}
```

总结：将所有的内存页都设置为占用，并经过计算，将主存区域的内存页设置为可用
