/*  ---------- 机器模式 ----------
    b -- 输出寄存器QImode名称，即寄存器中最低8位:[a-d]l
    w -- 输出寄存器HImode名称，即寄存器中2个字节的部分，如[a-d]x

    HImode:"Half-Integer"模式，半字,即一个2字节整数
    QImode:"Quarter-Integer"描述，半字,即一个1字节的整数
---------------------------------*/
#ifndef __LIB_IO_H
#define __LIB_IO_H
#include "stdint.h"

// 向port端口写入一个字节
static inline void outb(uint16_t port, uint8_t data)
{
    /* 对端口指定N表示0~255,
        d表示用dx存储端口号,
        %b0表示对应al,
        %w1表示对应dx
    */
    asm volatile("outb %b0,%w1" ::"a"(data), "Nd"(port));
}

// 从port端各存器读取一个字节
static inline uint8_t inb(uint16_t port)
{
    uint8_t data;
    asm volatile("inb %w1,%b0"
                 : "=a"(data)
                 : "Nd"(port));
    return data;
}

// 将addr处起始的word_cnt个字(2字节)写入端口port
static inline void outsw(uint16_t port, const void *addr, uint32_t word_cnt)
{
    /*
        +S:放在esi中，输入并输出
        +c:放在ecx中，输入并输出
        d:放在edx中
        这里ds,ed,ss段选择子早已在进入保护模式时初始化
    */
    // TODO:这里的addr和word_cnt为什么需要获取输出呢,不是没有使用到吗?
    asm volatile("cld;\
                    rep outsw;"
                 : "+S"(addr), "+c"(word_cnt)
                 : "d"(port));
}

// 将从端口port处读入的word_cnt个字(2字节)写入addr
static inline void insw(uint16_t port, void *addr, uint32_t word_cnt)
{
    /*
        +D:放在edi中,输入并输出
        +c:ecx中,I&O
    */
    asm volatile("cld;\
                    rep insw;"
                 : "+D"(addr), "+c"(word_cnt)
                 : "d"(port)
                 : "memory");
}

#endif /* __LIB_IO_H */
