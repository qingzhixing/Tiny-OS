#ifndef __KERNEL_MEMORY_H
#define __KERNEL_MEMORY_H
#include "bitmap.h"
#include "stdint.h"
struct virtual_addr
{
    struct bitmap vaddr_bitmap; // 虚拟地址用到的位图结构
    uint32_t vaddr_start;       // 虚拟地址的起始地址
};

extern struct pool kernel_pool, user_pool;
void mem_init(void);
void print_pool_info(struct pool *);
void print_vaddr_info(struct virtual_addr *);

// 内存池标记，用于判断使用哪个内存池
enum pool_flags
{
    PF_KERNEL = 1, // 内核内存池
    PF_USER = 2    // 用户内存池
};

// 以下属性的值是按位次来定义的，并不是0和1
// 页存在位：存在
#define PG_P_1 1
// 页存在位：不存在
#define PG_P_0 0
// R/W位 = 0: 读/执行
#define PG_RW_R 0
// R/W位 = 1: 读/写/执行
#define PG_RW_W 2
// U/S位 = 0: 系统级
#define PG_US_S 0
// U/S位 = 1: 用户级
#define PG_US_U 4

#endif /* __KERNEL_MEMORY_H */
