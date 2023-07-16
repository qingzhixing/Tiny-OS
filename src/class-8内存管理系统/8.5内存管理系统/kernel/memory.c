#include "memory.h"
#include "print.h"
#include "stdint.h"

// 一个页的尺寸：4096B=4kB
#define PG_SIZE 4096

/*
 * 位图地址
 * 0xc009f00是内核主线程栈顶，0xc009e00是内核主线程的pcb
 * 一个页框大小(4kB)的位图可表示128MB的内存：4kByte = 32kbit => 32k*4kB = 128MB
 * 位图地址安排在0xc009a00,这样本系统最大支持4个页框的位图即512MB
 */
#define MEM_BITMAP_BASE 0xc009a00

/*
 * 0xc0000000是内核，从虚拟地址3G起。
 * 0xc0100000是跨越低端1MB内存，使虚拟地址在逻辑上连续
 */
#define K_HEAP_START 0xc010_0000

// 内存池结构，生成两个实例用于管理内核物理内存池与用户物理内存池
struct pool
{
    struct bitmap pool_bitmap; // 本内存池用到的位图结构，用于管理物理内存
    uint32_t phy_addr_start;   // 本内存池所管理的物理内存的起始地址
    uint32_t pool_size;        // 本内存池字节容量
};

struct pool kernel_pool, user_pool; // 生成内核内存池与用户内存池