#include "debug.h"
#include "interrupt.h"
#include "print.h"

// 打印文件名，行号，函数名，条件，并使程序悬停
void panic_spin(
    char *filename,
    int line,
    const char *function_name,
    const char *condition)
{
    intr_disable(); // 有的时候会单独调用panic_spin,故再次关闭中断
    put_str("\n\n\n ---------- PANIC !!!!! ----------\n");
    put_str("File Name: ");
    put_str(filename);
    put_char('\n');
    put_str("Line: ");
    put_int_hex_prefixed(line);
    put_char('\n');
    put_str("Function Name: ");
    put_str(function_name);
    put_char('\n');
    put_str("Condition: ");
    put_str(condition);
    put_char('\n');

    // 悬停程序
    while (1)
    {
    }
}