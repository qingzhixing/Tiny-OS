#include "print.h"
int main(void)
{
    uint8_t message[] = "Kernel Message:put_char();\n";
    uint8_t pointer = 0;
    while (message[pointer] != '\0')
    {
        put_char(message[pointer++]);
    }
    while (1)
    {
        // 阻塞
    }
}