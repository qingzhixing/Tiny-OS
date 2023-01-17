; 直接绝对远转移
section call_test vstart=0x900
    ; 远转移机器码偏移地址在前，段地址在后
    jmp 0:start
times 128 db 0
start:
    mov ax,0x1234
    jmp $