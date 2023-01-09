; 相对短转移
section call_test vstart=0x900
    jmp short start
times 127 db 0
start:
    mov ax,0x1234
    jmp $