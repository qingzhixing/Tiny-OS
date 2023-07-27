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
 * 0xc009e00-0x4000(4kB)=0xc009_a000
 */
#define MEM_BITMAP_BASE 0xc009a000

/*
 * 0xc0000000是内核，从虚拟地址3G起。
 * 0xc0100000是跨越低端1MB内存，使虚拟地址在逻辑上连续
 */
#define K_HEAP_START 0xc0100000

#define PDE_IDX(addr) ((addr & 0xffc00000) >> 22)
#define PTE_IDX(addr) ((addr & 0x003ff000) >> 12)

// 内存池结构，生成两个实例用于管理内核物理内存池与用户物理内存池
struct pool
{
    struct bitmap pool_bitmap; // 本内存池用到的位图结构，用于管理物理内存
    uint32_t phy_addr_start;   // 本内存池所管理的物理内存的起始地址
    uint32_t pool_size;        // 本内存池字节容量
};

/*
    在pf表示的虚拟内存池中申请pg_cnt个虚拟页
    成功返回虚拟页的起始地址，失败则返回NULL
*/
static void *vaddr_get(enum pool_flags pf, uint32_t pg_cnt)
{
    int vaddr_start = 0, bit_idx_start = -1;

    // TODO:止步于此
}

void print_pool_info(struct pool *pool)
{
    print_bitmap_info(&pool->pool_bitmap);
    DEBUG_PRINT_UINT32_VAR(pool->phy_addr_start);
    DEBUG_PRINT_UINT32_VAR(pool->pool_size);
    put_char('\n');
}

void print_vaddr_info(struct virtual_addr *vaddr)
{
    print_bitmap_info(&vaddr->vaddr_bitmap);
    DEBUG_PRINT_UINT32_VAR(vaddr->vaddr_start);
    put_char('\n');
}

struct pool kernel_pool, user_pool; // 生成内核内存池与用户内存池

struct virtual_addr kernel_vaddr; // 给内核分配虚拟地址

/*
 * 初始化内存池
 * all_mem: 内存总量
 */
static void mem_pool_init(uint32_t all_mem)
{
    put_str("   mem_pool_init start\n");
    DEBUG_PRINT_UINT32_VAR(all_mem);

    // 页表大小 = 1页的页目录项 + 第0和第768个页目录项指向同一个页表 +
    //  第769~1022个页目录项共指向254个页表，一共有256个页表
    //  故大小为256*PG_SIZE=0x10_0000字节(1MB)
    uint32_t page_table_size = PG_SIZE * 256;
    DEBUG_PRINT_UINT32_VAR(page_table_size);

    // 0x10_0000为低端1MB内存
    uint32_t used_mem = page_table_size + 0x100000;
    DEBUG_PRINT_UINT32_VAR(used_mem);

    uint32_t free_mem = all_mem - used_mem;

    // 1页为4kB,不管内存是不是4k的倍数，对于以页位单位的内存分配策略，不足一页的内存就不用考虑了
    // 为简化位图操作，余数不做处理，坏处就是会丢内存
    // 好处就是不用做内存的越界检查，因为位图表示的内存少于实际的物理内存
    uint16_t all_free_page = free_mem / PG_SIZE;

    uint16_t kernel_free_pages = all_free_page / 2;

    uint16_t user_free_pages = all_free_page - kernel_free_pages;

    // Kernel BitMap 长度，位图中一位表示一页，8位为一字节，长度以字节为单位
    uint32_t kbm_length = kernel_free_pages / 8;

    // User BitMap 长度
    uint32_t ubm_length = user_free_pages / 8;

    // Kernel Pool Start,内核内存池的起始地址
    uint32_t kp_start = used_mem;

    // User Pool Start,用户内存池的起始地址
    uint32_t up_start = kp_start + kernel_free_pages * PG_SIZE;

    kernel_pool.phy_addr_start = kp_start;
    user_pool.phy_addr_start = up_start;

    kernel_pool.pool_size = kernel_free_pages * PG_SIZE;
    user_pool.pool_size = user_free_pages * PG_SIZE;

    kernel_pool.pool_bitmap.btmp_bytes_len = kbm_length;
    user_pool.pool_bitmap.btmp_bytes_len = ubm_length;

    // 内核内存池和用户内存池位图
    // 位图是全局数据，长度不固定
    // 全局或者静态的数组需要在编译时知道其长度
    // 我们需要根据总内存大小计算出需要多少字节
    // 所以改为指定一块内存来生成位图

    // 内核使用的最高地址是0xc009f000,这是主线程的栈地址
    // (内核大小估计为70kb左右)
    // 32MB内存占用位图是2KB
    // 内核内存池的位图先定义在MEM_BITMAP_BASE(0xc009_a000)
    kernel_pool.pool_bitmap.bits = (void *)MEM_BITMAP_BASE;

    // 用户内存池的位图紧跟在内核内存池位图之后
    user_pool.pool_bitmap.bits = (void *)(MEM_BITMAP_BASE + kbm_length);

    // 将位图置0
    bitmap_init(&kernel_pool.pool_bitmap);
    bitmap_init(&user_pool.pool_bitmap);

    // 初始化内核虚拟地址位图，按实际物理内存大小生成数组
    // 用于维护内核 堆 的虚拟地址，所以要和内核内存池的大小一致
    kernel_vaddr.vaddr_bitmap.btmp_bytes_len = kbm_length;

    // 位图的数组指向一块未使用的内存
    // 目前定位在内核内存池和用户内存池之外
    kernel_vaddr.vaddr_bitmap.bits = (void *)(MEM_BITMAP_BASE + kbm_length + ubm_length);

    kernel_vaddr.vaddr_start = K_HEAP_START;

    bitmap_init(&kernel_vaddr.vaddr_bitmap);

    put_str('\n');

    // 输出内存池信息
    put_str("Kernel Pool Info:\n");
    print_pool_info(&kernel_pool);
    put_str("User Pool Info:\n");
    print_pool_info(&user_pool);

    // 输出虚拟地址信息
    put_str("Kernel Vaddr Info:\n");
    print_vaddr_info(&kernel_vaddr);

    put_str("   mem_pool_init done\n");
}

void mem_init()
{
    put_str("mem_init start\n");
    // 读取0xb00处数据
    uint32_t mem_bytes_total = (*(uint32_t *)(0xb00));
    mem_pool_init(mem_bytes_total); // 初始化内存池
    put_str("mem_init done\n");
}