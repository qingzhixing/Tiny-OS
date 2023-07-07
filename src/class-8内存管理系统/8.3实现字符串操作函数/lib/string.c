#include "string.h"
#include "debug.h"
#include "global.h"
#include "stddef.h"

// 设置从distance起始的size个字节设置为value
void memset(void *p_distance, uint8_t value, uint32_t size)
{
    ASSERT(p_distance != nullptr);
    uint8_t *u8p_distance = (uint8_t *)p_distance;
    while (size-- > 0)
    {
        *u8p_distance++ = value;
    }
}

// 将p_source起始的size个字节复制到distance
void memcpy(void *p_distance, const void *p_source, uint32_t size)
{
    ASSERT(p_distance != nullptr && p_source != nullptr);
    uint8_t *u8p_distance = (uint8_t *)p_distance;
    const uint8_t *u8p_source = (uint8_t *)p_source;
    while (size-- > 0)
    {
        *u8p_distance++ = *u8p_source++;
    }
}

// 连续比较地址p_a和p_开头的size个字节，若相等则返回0
// p_a>p_b返回+1否则返回-1
int memcmp(const void *p_a, const void *p_b, uint32_t size)
{
    ASSERT(p_a != nullptr && p_b != nullptr);
    const uint8_t *u8p_a = (const uint8_t *)p_a;
    const uint8_t *u8p_b = (const uint8_t *)p_b;
    while (size-- > 0)
    {
        if (*u8p_a != *u8p_b)
        {
            return (*u8p_a > *u8p_b) ? 1 : -1;
        }
        u8p_a++;
        u8p_b++;
    }
    return 0;
}

// 将字符串source_str复制到distance_str
char *strcpy(char *distance_str, const char *source_str)
{
    ASSERT(distance_str != nullptr && source_str != nullptr);
    char *remote_str = distance_str; // 返回目的字符串的起始地址
    // *source_str!='\0'就一直复制
    while ((*remote_str++ = *source_str++) != '\0')
    {
    }
    return remote_str;
}

// 返回字符串长度
uint32_t strlen(const char *str)
{
    ASSERT(str != nullptr);
    const char *pointer = str;
    while (*pointer++)
    {
    }
    return (pointer - str - 1);
}

// str1 > str2 : +1
// str1 == str2 : 0
// str1 < str2 : -1
int8_t strcmp(const char *str1, const char *str2)
{
    ASSERT(str1 != nullptr && str2 != nullptr);
    put_str("comparing:\n");
    put_str(str1);
    put_char('\n');
    put_str(str2);
    put_char('\n');
    while (*str1 != 0 && *str1 == *str2)
    {
        str1++;
        str2++;
    }
    return (*str1 < *str2) ? -1 : ((*str1 > *str2) ? 1 : 0);
}

// 从左往右查找字符串str中首次出现ch的地址
// 没找到返回nullptr
char *strchr(const char *str, const uint8_t ch)
{
    ASSERT(str != nullptr);
    while (*str != 0)
    {
        if (*str == ch)
        {
            return (char *)str;
        }
        str++;
    }
    return nullptr;
}

// 从右往左查找字符串str中首次出现ch的地址
// 没找到返回nullptr
char *strrchr(const char *str, const uint8_t ch)
{
    ASSERT(str != nullptr);
    const char *last_char = nullptr;
    while (*str != 0)
    {
        if (*str == ch)
        {
            last_char = str;
        }
        str++;
    }
    return (char *)last_char;
}

// 将source_str拼接到distance_str后并返回拼接的字符串地址
char *strcat(char *distance_str, const char *source_str)
{
    ASSERT(distance_str != nullptr && source_str != nullptr);
    char *pointer = distance_str;
    // str移动到最后一个字符(非\0)位置
    while (*pointer++)
    {
    }
    --pointer;

    while (*source_str != 0)
    {
        *pointer++ = *source_str++;
    }
    *pointer = 0;
    ASSERT(*pointer == 0);
    return distance_str;
}

uint32_t strchrs(const char *str, uint8_t ch)
{
    ASSERT(str != nullptr);
    uint32_t counter = 0;
    const char *pointer = str;
    while (*pointer != 0)
    {
        if (*pointer == ch)
        {
            counter++;
        }
        pointer++;
    }
    return counter;
}