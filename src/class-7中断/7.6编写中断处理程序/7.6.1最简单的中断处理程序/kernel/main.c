#include "print.h"
int main(void)
{
    char message[] = "Kernel Message:put_str();\n";
    put_str(message);
    put_int_hex(0xFFFFFFFF);
    while (1)
    {
        // 阻塞
    }
}