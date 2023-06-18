#include "print.h"
int main(void)
{
    char message[] = "Kernel Message:put_str();";
    put_str(message);
    while (1)
    {
        // 阻塞
    }
}