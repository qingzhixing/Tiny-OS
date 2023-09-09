#include "debug.h"
#include "init.h"
#include "print.h"
#include "stddef.h"
#include "string.h"
int main(void)
{
    put_str("\nKernel Running.\n");
    init_all();

    BochsMagicBreak();

    void *vaddr = get_kernel_pages(3);
    put_str("\nget_kernel_pages start vaddr is ");
    put_int_hex((uint32_t)vaddr);
    put_char('\n');

    // 阻塞
    while (true)
    {
        BochsMagicBreak();
        void *vaddr = get_kernel_pages(1);
        put_str("\nget_kernel_pages start vaddr is ");
        put_int_hex((uint32_t)vaddr);
        put_char('\n');
    }
}