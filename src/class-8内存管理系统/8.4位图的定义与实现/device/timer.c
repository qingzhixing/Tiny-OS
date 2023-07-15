#include "timer.h"
#include "io.h"
#include "print.h"

// 时钟中断频率为100Hz
#define IRQ0_FREQUENCY 100
// 计数器工作频率为1.193180MHz
#define INPUT_FREQUENCY 1193180
#define COUNTER0_VALUE INPUT_FREQUENCY / IRQ0_FREQUENCY
#define COUNTER0_PORT 0x40
#define COUNTER0_ID 0
// 工作方式: 0bX10 方式2:比率发生器(Rate Generator)
#define COUNTER0_MODE 0b010
// 读写锁 0b11:先读写低字节再读写高字节
#define READ_WRITE_LATCH 3
#define PIT_CONTROL_PORT 0x43

/*
    将:
        counter_id:操作的计数器
        read_write_latch:读写锁属性
        counter_mode:计数器模式
    写入模式控制寄存器:counter_port
    并赋予初始值counter_value
*/
static void set_frequency(
    uint8_t counter_port,
    uint8_t counter_id,
    uint8_t read_write_latch,
    uint8_t counter_mode,
    uint16_t counter_value)
{
    // 写入控制字
    outb(PIT_CONTROL_PORT,
         (uint8_t)(counter_id << 6 | read_write_latch << 4 | counter_mode << 1));
    // 写入counter_value低8位
    outb(counter_port, (uint8_t)counter_value);
    // 写入高8位
    outb(counter_port, (uint8_t)(counter_value >> 8));
}

// 初始化PIT8253
void timer_init()
{
    put_str("timer_init start\n");
    // 设置定时周期，即发中断的周期
    set_frequency(
        COUNTER0_PORT,
        COUNTER0_ID,
        READ_WRITE_LATCH,
        COUNTER0_MODE,
        COUNTER0_VALUE);
    put_str("timer_init done\n");
}