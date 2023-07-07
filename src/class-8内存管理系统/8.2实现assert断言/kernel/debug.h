#ifndef __KERNEL_DEBUG_H
#define __KERNEL_DEBUG_H
#define ALWAYS_INLINE inline __attribute__((always_inline))

static ALWAYS_INLINE void BochsMagicBreak(void)
{
    asm volatile("xchg %bx,%bx");
}

void panic_spin(
    char *filename,
    int line,
    const char *function_name,
    const char *condition);

#define PANIC(...) panic_spin(__FILE__, __LINE__, __func__, __VA_ARGS__)

#ifdef NDEBUG
#define ASSERT(CONDITION) ((void)0)
#else
#define ASSERT(CONDITION)                                  \
    if (CONDITION)                                         \
    {                                                      \
    }                                                      \
    else                                                   \
    {                                                      \
        /*符号#将CONDITION转变为字符串字面量*/ \
        PANIC(#CONDITION);                                 \
    }
#endif // NDEBUG

#endif /* __KERNEL_DEBUG_H */
