#include <stdio.h>
int count = 0;
int main(void)
{
    asm("   movl $1,%eax;\
            movl $2,%ebx;\
            add %ebx,%eax;\
            mov %eax,count");
    printf("1+2=%d\n", count);
    return 0;
}