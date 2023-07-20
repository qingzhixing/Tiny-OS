#ifndef __LIB_KERNEL_BITMAP_H
#define __LIB_KERNEL_BITMAP_H
#include "global.h"
#define BITMAP_MASK 1
struct bitmap
{
    uint32_t btmp_bytes_len;
    // 遍历位图时，整体上以字节为单位，细节上以位为单位，
    // 故这里位图指针必须是单字节
    uint8_t *bits;
};

void bitmap_init(struct bitmap *);
bool bitmap_scan_test(struct bitmap *, uint32_t);
int bitmap_scan(struct bitmap *, uint32_t);
void bitmap_set(struct bitmap *, uint32_t, int8_t);
void print_bitmap_info(struct bitmap *);
#endif /* __LIB_KERNEL_BITMAP_H */
