#ifndef __KERNEL_DEBUG_H
#define __KERNEL_DEBUG_H
#define ALWAYS_INLINE inline __attribute__((always_inline))

static ALWAYS_INLINE void BochsMagicBreak()
{
    asm volatile("xchg %bx,%bx");
}

#endif /* __KERNEL_DEBUG_H */
