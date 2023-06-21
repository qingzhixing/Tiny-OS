#include <stdio.h>
int main()
{
    int in_a = 1, in_b = 0xffff;
    printf("in_b is %d\n", in_b);
    //%b0:al
    asm("movb %b0,%1" ::"a"(in_a), "m"(in_b));
    printf("in_b is %d\n", in_b);

    //这里比较movb和movl的区别
    asm("movl $114,%0" ::"m"(in_b));
    printf("in_b is %d\n", in_b);
    return 0;
}