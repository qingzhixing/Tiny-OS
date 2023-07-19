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
 * 0xc009e00-0x4000(4kB)=0xc009a00
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

struct virtual_addr kernel_vaddr; // 给内核分配虚拟地址

/*
 * 初始化内存池
 * all_mem: 内存总量
 */
static void mem_pool_init(uint32_t all_mem)
{
    put_str("   mem_pool_init start\n");

    // 页表大小 = 1页的页目录项 + 第0和第768个页目录项指向同一个页表 +
    //  第769~1022个页目录项共指向254个页表，一共有256个页表
    //  故大小为256*PG_SIZE=0x20_0000字节(2MB)
    uint32_t page_table_size = PG_SIZE * 256;

    // 0x10_0000为低端1MB内存
    uint32_t used_mem = page_table_size + 0x10_0000;

    uint32_t free_mem = all_mem - used_mem;

    // 1页为4kB,不管内存是不是4k的倍数，对于以页位单位的内存分配策略，不足一页的内存就不用考虑了
    uint16_t all_free_page = free_mem / PG_SIZE;
}