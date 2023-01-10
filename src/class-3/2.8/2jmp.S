; 相对近转移:-32768~32767
section call_test vstart=0x900
    jmp near start
times 128 db 0
start:
    mov ax,0x1234
    jmp $