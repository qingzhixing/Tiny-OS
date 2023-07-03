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
    // 对端口指定N表示0~255,d表示用dx存储端口号,%b0表示对应al,%w1表示对应dx
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

// 将addr处起始的word_cnt个字写入端口port
static inline void outw(uint16_t port,)//TODO:止步于此

#endif /* __LIB_IO_H */
