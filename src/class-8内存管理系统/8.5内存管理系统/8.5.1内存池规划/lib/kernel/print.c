#include "print.h"

void put_int(uint32_t number)
{
    uint8_t digit = 0;
    uint8_t buffer[16];
    do
    {
        buffer[digit++] = number % 10 + '0';
        number /= 10;
    } while (number != 0);

    // 倒序输出，因为在buffer中低位在前，而实际上低位在输出中在字符串后端
    for (int8_t pointer = digit - 1; pointer >= 0; pointer--)
    {
        put_char(buffer[pointer]);
    }
}

void put_int_hex_prefixed(uint32_t number)
{
    put_str("0x");
    put_int_hex(number);
}