#ifndef __THREAD_THREAD_H
#define __THREAD_THREAD_H
#include "stdint.h"

// 自定义通用函数类型，将在很多线程函数中作为形参使用
typedef void thread_func(void *);

/*进程或者线程的状态*/
enum task_status
{
    TASK_RUNNING,
    TASK_READY,
    TASK_BLOCKED,
    TASK_WAITING,
    TASK_HANGING,
    TASK_DIED
};

/*
    中断栈 intr_stack
    中断发生时会按照此结构压入上下文寄存器
    intr_exit 中出栈操作是此结构的逆操作
    此栈在线程自己的内核栈中位置固定，所以在页的最顶端(?)
*/
struct intr_stack
{
    uint32_t vec_id; // kernel.S 宏VECTOR中push %1压入的中断号
    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t esp_dummy; // pushad会压入esp,但esp不断变化，会被popad忽略，不会赋值
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;
    uint32_t gs;
    uint32_t fs;
    uint32_t es;
    uint32_t ds;

    // 以下由cpu从低特权级进入高特权级时压入
    uint32_t err_code; // err_code 会被压入在eip之后
    void (*eip)(void);
    uint32_t cs;
    uint32_t eflags;
    void *esp;
    uint32_t ss;
};
#endif /* __THREAD_THREAD_H */
