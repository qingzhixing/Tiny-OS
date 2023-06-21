#include <stdio.h>
int main()
{
    int in_a = 18, in_b = 3, out = 0;
    asm("divb %b[divisor];movb %%al,%[result];"
        : [result] "=m"(out)
        : "a"(in_a), [divisor] "b"(in_b));
    printf("result is %d\n", out);
    return 0;
}