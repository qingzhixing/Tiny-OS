section loader vstart=0x900
    ; 段寄存器入栈按当前模式(实模式/保护模式)默认操作数大小压入
    mov sp,0x900
    push cs; 2字节
    push ds; 2字节
    push es; 2字节
    jmp $