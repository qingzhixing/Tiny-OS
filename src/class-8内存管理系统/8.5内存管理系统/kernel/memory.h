#ifndef __KERNEL_MEMORY_H
#define __KERNEL_MEMORY_H
#include "bitmap.h"
#include "stdint.h"
struct virtual_addr
{
    struct bitmap vaddr_bitmap; // 堵你地址用到的位图结构
    uint32_t vaddr_start;       // 虚拟地址的起始地址
};

extern struct pool kernel_pool, user_pool;
void mem_init(void);

#endif /* __KERNEL_MEMORY_H */
