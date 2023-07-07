#include "debug.h"
#include "init.h"
#include "print.h"
int main(void)
{
    put_str("\nKernel Running.\n");
    init_all();
    BochsMagicBreak();
    // 将eflags IF位置1,使cpu可以处理外部中断
    asm volatile("sti");
    ASSERT(1 == 2);
    while (1)
    {
        // 阻塞
    }
}