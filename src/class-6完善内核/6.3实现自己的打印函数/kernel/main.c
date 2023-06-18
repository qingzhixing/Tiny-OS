#include "print.h"
void main(void)
{
    uint8_t kernelMessage[] = "kernel message\n";
    uint8_t pointer = 0;
    while (kernelMessage[pointer] != '\0')
    {
        put_char(kernelMessage[pointer++]);
    }
}