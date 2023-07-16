#include "memory.h"
#include "print.h"
#include "stdint.h"

// 一个页的尺寸：4096B=4kB
#define PG_SIZE 4096

/*  位图地址
 * 0xc009f00是内核主线程栈顶，0xc009e00是内核主线程的pcb
 * 一个页框大小(4kB)的位图可表示128MB的内存：4kByte = 32kbit => 32k*4kB = 128MB
 * 位图地址安排在0xc009a00,这样本系统最大支持4个页框的位图即512MB
 * 我们的内核大小不超过512MB
 */
#define MEM_BITMAP_BASE 0xc009a00