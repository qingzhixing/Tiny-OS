#ifndef __LIB_KERNEL_PRINT_H
#define __LIB_KERNEL_PRINT_H
#include "stdint.h"
extern void put_char(uint8_t char_asci);
extern void put_str(const char *str);
extern void put_int_hex(uint32_t number);
void put_int(uint32_t number);
void put_int_hex_prefixed(uint32_t number);

#define DEBUG_PRINT_UINT32_VAR(UINT32_VAR_NAME) \
    put_str(#UINT32_VAR_NAME);                  \
    put_str(": ");                              \
    put_int_hex_prefixed(UINT32_VAR_NAME);      \
    put_char(' ');
#endif /* __LIB_KERNEL_PRINT_H */
