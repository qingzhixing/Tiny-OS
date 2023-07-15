#include "debug.h"
#include "init.h"
#include "print.h"
#include "string.h"
int main(void)
{
    put_str("\nKernel Running.\n");
    init_all();
    BochsMagicBreak();
    // 将eflags IF位置1,使cpu可以处理外部中断
    asm volatile("sti");
    ASSERT(strcmp("abc", "abc") == 0);
    ASSERT(strcmp("abc", "abd") < 0);
    // 我们没有对strcat进行内存管理导致调用时会把后面字符串顶掉，所以我们程序停留在此
    ASSERT(strcmp(strcat("114514", "1919810"), "1145141919810") == 0);
    ASSERT(1 == 2);
    while (1)
    {
        // 阻塞
    }
}