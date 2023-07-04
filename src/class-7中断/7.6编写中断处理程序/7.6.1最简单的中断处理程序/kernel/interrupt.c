#include "interrupt.h"
#include "global.h"
#include "stdint.h"

// 目前支持的总中断数
#define IDT_DESC_CNT 0x21

// 门描述符结构体(中断门描述符通用)
struct gate_desc
{
    uint16_t func_offset_low_word; // 处理程序低16位指针地址
    uint16_t selector;
    uint8_t dcount; // 双字计数字段，是门描述符中第四字节
}