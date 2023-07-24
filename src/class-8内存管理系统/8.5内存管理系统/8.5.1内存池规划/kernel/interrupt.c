#include "interrupt.h"
#include "global.h"
#include "io.h"
#include "print.h"
#include "stdint.h"

// 目前支持的总中断数
#define IDT_DESC_CNT 0x21

// pic参数
// 主片的控制端口是0x20
#define PIC_MASTER_CTRL 0x20
// 主片的数据端口是0x21
#define PIC_MASTER_DATA 0x21
// 从片的控制端口是0xa0
#define PIC_SLAVE_CTRL 0xa0
// 从片的数据端口水0xa1
#define PIC_SLAVE_DATA 0xa1

// 中断开关相关参数
#define EFLAGS_IF 0x00000200
#define GET_EFLAGS(EFLAGS_VAR) asm volatile("pushfl; popl %0" \
                                            : "=g"(EFLAGS_VAR))

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
char *intr_name[IDT_DESC_CNT];                      // 用于保存异常的名字
intr_handler idt_handler_table[IDT_DESC_CNT];
// 定义中断处理程序数组,在kernel.S中定义的intr_XX_entry
// 只是中断处理程序的入口,最终调用的是idt_entry_table中的处理程序
// 是为了中断管理与执行分离

// 创建中断门描述符
static void make_idt_desc(struct gate_desc *p_gdesc, uint8_t attr, intr_handler handler)
{
    p_gdesc->func_offset_low_word = (uint32_t)(handler)&0x0000FFFF;
    p_gdesc->selector = SELECTOR_K_CODE;
    p_gdesc->dcount = 0;
    p_gdesc->attribute = attr;
    p_gdesc->func_offset_high_word = (uint32_t)(handler) >> 16;
}

// 通用的中断处理函数，一般用在异常出现时处理
static void general_intr_handler(uint8_t vec_nr)
{
    // IRQ7 和 IRQ15 会产生伪中断(spurious interrupt),无需处理
    // 0x2f是从片8259A上的最后一个IRQ引脚，保留项
    if (vec_nr == 0x27 || vec_nr == 0x2f)
    {
        return;
    }
    put_str("int vector: ");
    put_int_hex_prefixed(vec_nr);
    put_char('\n');
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

// 异常名初始化并注册通常的中断处理函数
static void exception_init(void)
{
    for (int i = 0; i < IDT_DESC_CNT; i++)
    {
        // idt_handler_table数组中的函数是在idt_entry_table指向的函数中调用的
        //  见kernel/kernel.S 的 call [idt_handler_table+%1*4]
        idt_handler_table[i] = general_intr_handler;
        // 之后会有register_handler为特定中断注册特定处理函数
        intr_name[i] = "Unknown";
    }
    intr_name[0] = "#DE Divide Error";
    intr_name[1] = "#DB Debug Exception";
    intr_name[2] = "NMI Interrupt";
    intr_name[3] = "#BP Breakpoint Exception";
    intr_name[4] = "#OF Overflow Exception";
    intr_name[5] = "#BR BOUND Range Exceeded Exception";
    intr_name[6] = "#UD Invalid Opcode Exception";
    intr_name[7] = "#NM Device Not Available Exception";
    intr_name[8] = "#DF Double Fault Exception";
    intr_name[9] = "Coprocessor Segment Overrun";
    intr_name[10] = "#TS Invalid TSS Exception";
    intr_name[11] = "#NP Segment Not Present";
    intr_name[12] = "#SS Stack Fault Exception";
    intr_name[13] = "#GP General Protection Exception";
    intr_name[14] = "#PF Page-Fault Exception";
    // intr_name[15] 第15项是intel保留项,未使用
    intr_name[16] = "#MF x87 FPU Floating-Point Error";
    intr_name[17] = "#AC Alignment Check Exception";
    intr_name[18] = "#MC Machine-Check Exception";
    intr_name[19] = "#XF SIMD Floating-Point Exception";
    // intr_name[80] = "SYSCALL INTR";
}

// 初始化8259A
static void pic_init(void)
{
    // 初始化主片
    outb(PIC_MASTER_CTRL, 0x11); // ICW1:边沿触发，级联8259,需要ICW4
    outb(PIC_MASTER_DATA, 0x20); // ICW2: 起始中断向量号为0x20
                                 // 也就是IR[0-7]为0x20~0x27
    outb(PIC_MASTER_DATA, 0x04); // ICW3:IR2接从片
    outb(PIC_MASTER_DATA, 0x01); // ICW4: 8086模式，正常EOI

    // 初始化从片
    outb(PIC_SLAVE_CTRL, 0x11); // ICW1:边沿触发，级联8259,需要ICW4
    outb(PIC_SLAVE_DATA, 0x28); // ICW2: 起始中断向量号为0x28
                                // 也就是IR[8-15]位0x28~0x2F
    outb(PIC_SLAVE_DATA, 0x02); // ICW3:从片连接到主片IR2引脚
    outb(PIC_SLAVE_DATA, 0x01); // ICW4: 8086模式，正常EOI

    // 只打开IR0,也就是只接受时钟中断
    // IR0在主片上
    outb(PIC_MASTER_DATA, 0xfe);
    outb(PIC_SLAVE_DATA, 0xff);

    put_str("   pic_init done\n");
}

// 完成所有中断的初始化工作
void idt_init()
{
    put_str("idt_init start\n");
    idt_desc_init();  // 初始化中断描述符表
    exception_init(); // 异常名初始化并注册通常的中断处理函数
    pic_init();       // 初始化8259A

    // 加载idt
    uint64_t idt_operand = (uint64_t)((uint32_t)idt << 16) | (sizeof(idt) - 1);
    asm volatile("lidt %0" ::"m"(idt_operand));
    put_str("idt_init done\n");
}

// 获取当前中断状态
enum intr_status intr_get_status()
{
    uint32_t eflags = 0;
    GET_EFLAGS(eflags);
    return (EFLAGS_IF & eflags) ? INTR_ON : INTR_OFF;
}

// 开启中断并返回开启之前的状态
enum intr_status intr_enable()
{
    if (INTR_ON == intr_get_status())
    {
        return INTR_ON;
    }
    else
    {
        asm volatile("sti");
        return INTR_OFF;
    }
}

// 关闭中断并返回关闭之前的状态
enum intr_status intr_disable()
{
    if (INTR_OFF == intr_get_status())
    {
        return INTR_OFF;
    }
    else
    {
        asm volatile("cli" ::
                         : "memory"); // 关闭中断,cli将IF为置0
        return INTR_ON;
    }
}

// 将中断状态设置为status并返回上一个状态
enum intr_status intr_set_status(enum intr_status status)
{
    return (INTR_ON == status) ? intr_enable() : intr_disable();
}