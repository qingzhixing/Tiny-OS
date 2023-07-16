#include "debug.h"
#include "init.h"
#include "print.h"
#include "string.h"
int main(void)
{
    put_str("\nKernel Running.\n");
    init_all();
    BochsMagicBreak();
    ASSERT(1 == 2);
    while (1)
    {
        // 阻塞
    }
}