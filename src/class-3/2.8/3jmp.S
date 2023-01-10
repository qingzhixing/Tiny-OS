; 间接绝对短转移
section call_test vstart=0x900
    mov ax,start
    ; register size specification ignore报错
    ;   为near放在寄存器前导致,是正常现象
    jmp near ax
times 128 db 0
start:
    mov ax,0x1234
    jmp $