[bits 32]
%define ERROR_CODE nop  ; 若相关代码中CPU已经自动压入错误码，
                        ; 为保证栈中格式统一，这里不做操作

%define ZERO push 0     ; 若CPU未自动压入错误码，为统一
                        ; 栈中格式，手工压入一个0

extern put_str          ; 声明外部函数

section .data
    intr_str db "interrupt occur",0xa,0
    global intr_entry_table
    intr_entry_table:   ; 预处理之后的.data在生成elf之后
                        ; 会合并到后面，即这是intr enrties的数组指针

; 在 %1 进行 %2 操作
; %1: 中断号
; %2: 压入或者不压入错误码的处理语句，在之后展开
%macro VECTOR 2
section .text
    intr_%1_entry:  ; 每个中断处理程序都要压入中断向量号，所以
                    ; 一个中断类型对应一个中断处理程序
                    ; 自己知道自己的中断向量号是多少

        %2          ; 展开，对于CPU压入错误码的为:nop
                    ; 对于CPU不压入错误码的手动压入0
        push intr_str
        call put_str
        add esp,4       ;弹出intr_str

        ;如果是从片上的中断，出了往从片上发送EOI,还要发主片
        mov al,0b0010_0000      ; 中断结束命令EOI
        out 0xa0,al             ; 从片
        out 0x20,al             ; 主片

        add esp,4               ; 弹出错误码或者手动压入的0
        iret                    ; 从中断返回
section .data           ; 储存各个中断入口程序的地址
    dd intr_%1_entry
%endmacro

; ZERO还是ERROR_CODE看书 表7-1
VECTOR 0x00 ,ZERO
VECTOR 0x01 ,ZERO
VECTOR 0x02 ,ZERO
VECTOR 0x03 ,ZERO
VECTOR 0x04 ,ZERO
VECTOR 0x05 ,ZERO
VECTOR 0x06 ,ZERO
VECTOR 0x07 ,ZERO
VECTOR 0x08 ,ERROR_CODE
VECTOR 0x09 ,ZERO
VECTOR 0x0A ,ERROR_CODE
VECTOR 0x0B ,ERROR_CODE
VECTOR 0x0C ,ERROR_CODE
VECTOR 0x0D ,ERROR_CODE
VECTOR 0x0E ,ERROR_CODE
VECTOR 0x0F ,ZERO
VECTOR 0x10 ,ZERO
VECTOR 0x11 ,ERROR_CODE
VECTOR 0x12 ,ZERO
VECTOR 0x13 ,ZERO
VECTOR 0x14 ,ZERO
VECTOR 0x15 ,ZERO
VECTOR 0x16 ,ZERO
VECTOR 0x17 ,ZERO
VECTOR 0x18 ,ZERO
VECTOR 0x19 ,ZERO
VECTOR 0x1A ,ZERO
VECTOR 0x1B ,ZERO
VECTOR 0x1C ,ZERO
VECTOR 0x1D ,ZERO
VECTOR 0x1E ,ERROR_CODE             ; 处理器自动推错误码
VECTOR 0x1F ,ZERO					
VECTOR 0x20 ,ZERO					; 时钟中断