section loader vstart=0x900
    mov sp,0x900
    ; 测试寄存器入栈
    push ax                 ; 2字节
    push eax                ; 4字节
    ; 测试内存入栈
    push word [0x1234]      ; 2字节
    push dword [0x1234]     ; 4字节

    jmp $