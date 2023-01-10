; 直接绝对远调用
section call_test vstart=0x900
    ; call far 0:far_proc 不过现在nasm编译器
    ; 不再支持call far的绝对远调用，只认call的绝对远调用
    call 0:far_proc
    jmp $
far_proc:
    mov ax,0x1234
    retf