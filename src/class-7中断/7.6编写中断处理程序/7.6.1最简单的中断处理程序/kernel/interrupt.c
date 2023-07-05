#include "interrupt.h"
#include "global.h"
#include "print.h"
#include "stdint.h"

// 目前支持的总中断数
#define IDT_DESC_CNT 0x21

// 门描述符结构体(中断门描述符通用)
struct gate_desc
{
    uint16_t func_offset_low_word; // 处理程序低16位指针地址
    uint16_t selector;
    uint8_t dcount; // 双字计数字段，是门描述符中第四字节
                    // 此项为固定值，不用考虑
    uint8_t attribute;
    uint16_t func_offset_high_word; // 处理程序高16位指针地址
};

static struct gate_desc idt[IDT_DESC_CNT]; // idt是中断描述符表
                                           // 本质上是个中断描述符数组

extern intr_handler intr_entry_table[IDT_DESC_CNT]; // 该声明的引用在kernel.S中，
                                                    // 为中断处理入口数组

// 创建中断门描述符
static void make_idt_desc(struct gate_desc *p_gdesc, uint8_t attr, intr_handler handler)
{
    p_gdesc->func_offset_low_word = (uint32_t)(handler)&0x0000FFFF;
    p_gdesc->selector = SELECTOR_K_CODE;
    p_gdesc->dcount = 0;
    p_gdesc->attribute = attr;
    p_gdesc->func_offset_high_word = (uint32_t)(handler) >> 16;
}

// 初始化中断描述符表
static void idt_desc_init(void)
{
    for (int i = 0; i < IDT_DESC_CNT; i++)
    {
        make_idt_desc(idt + i, IDT_DESC_ATTR_DPL0, intr_entry_table[i]);
    }
    put_str("   idt_desc_init done\n");
}

// 完成所有中断的初始化工作
void idt_init()
{
    put_str("idt_init start\n");
    idt_desc_init(); // 初始化中断描述符表
    pic_init();      // 初始化8259A

    // 加载idt
    uint64_t idt_operand = (uint64_t)((uint32_t)idt << 16) | (sizeof(idt) - 1);
    asm volatile("lidt %0" ::"m"(idt_operand));
    put_str("idt_init done\n");
}
