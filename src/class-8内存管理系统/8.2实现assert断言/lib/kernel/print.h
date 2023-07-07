#ifndef __LIB_KERNEL_PRINT_H
#define __LIB_KERNEL_PRINT_H
#include "stdint.h"
extern void put_char(uint8_t char_asci);
extern void put_str(char *str);
extern void put_int_hex(uint32_t num_hex);
#endif /* __LIB_KERNEL_PRINT_H */
