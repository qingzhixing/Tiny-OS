#include "bitmap.h"
#include "debug.h"
#include "interrupt.h"
#include "print.h"
#include "stdint.h"
#include "string.h"

// bitmap初始化
void bitmap_init(struct bitmap *btmp)
{
    memset(btmp->bits, 0, btmp->btmp_bytes_len);
}

// 判断bit_idx位是否为1，若为1,返回true,否则false
bool bitmap_scan_test(struct bitmap *btmp, uint32_t bit_idx)
{
    // 得到对应byte
    uint32_t byte_idx = bit_idx / 8;

    uint32_t bit_odd = bit_idx % 8;

    return btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd);
}

// 在位图中申请连续的cnt个位，成功返回起始位下标(bit)，否则失败返回-1
int bitmap_scan(struct bitmap *btmp, uint32_t cnt)
{
    uint32_t available_byte_index = 0;
    // 暴力逐字节比较
    while ((0xff == btmp->bits[available_byte_index]) && (available_byte_index < btmp->btmp_bytes_len))
    {
        // 1表示已被占用，若为0xff则该位无空闲，向下一字节继续查找
        available_byte_index++;
    }
    ASSERT(available_byte_index < btmp->btmp_bytes_len);
    // 无空闲
    if (available_byte_index == btmp->btmp_bytes_len - 1)
    {
        return -1;
    }

    // available byte中第一个0的位置
    uint32_t available_bit_index = 0;
    while (btmp->bits[available_byte_index] & (BITMAP_MASK << available_bit_index))
    {
        available_bit_index++;
    }

    // 空闲位在图中的下标
    int start_bit_index = available_byte_index * 8 + available_bit_index;
    if (cnt == 1)
    {
        return start_bit_index;
    }

    // 还剩下多少bit能判断
    uint32_t bit_left = btmp->btmp_bytes_len * 8 - start_bit_index;
    uint32_t next_bit_index = start_bit_index + 1;
    uint32_t counter = 1; // 总共找到了空闲位个数

    start_bit_index = -1; // 先置-1，找不到连续位则直接返回
    while (bit_left-- > 0)
    {
        if (bitmap_scan_test(btmp, next_bit_index) == 0)
        {
            counter++;
        }
        else
        {
            // 不连续则清空
            counter = 0;
        }
        if (counter == cnt)
        {
            start_bit_index = next_bit_index - cnt + 1;
            break;
        }
        next_bit_index++;
    }
    return start_bit_index;
}

// 将bitmap的bit_idx位置为value
void bitmap_set(struct bitmap *btmp, uint32_t bit_idx, int8_t value)
{
    ASSERT(value == 0 || value == 1);
    uint32_t byte_idx = bit_idx / 8;
    uint32_t bit_odd = bit_idx % 8;

    if (value == 1)
    {
        btmp->bits[byte_idx] |= (BITMAP_MASK << bit_odd);
    }
    else
    {
        btmp->bits[byte_idx] &= (BITMAP_MASK << bit_odd);
    }
}

void print_bitmap_info(struct bitmap *btmp)
{
    put_str("   Bitmap Length: ");
    put_int_hex(btmp->btmp_bytes_len);
    put_char(' ');
    put_str("   Bitmap Bytes Start: ");
    put_int_hex((uint32_t)btmp->bits);
    put_char('\n');
}