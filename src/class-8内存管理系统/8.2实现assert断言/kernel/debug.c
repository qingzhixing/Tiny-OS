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
    put_str("file name:");
    put_str(filename);
    put_char('\n');
    put_str("line: 0x");
    put_int_hex(line);
    put_char('\n');
    put_str("function name:");
    put_str((char *)function_name);
    put_char('\n');
    put_str("condition:");
    put_str((char *)condition);
    put_char('\n');

    // 悬停程序
    while (1)
    {
    }
}