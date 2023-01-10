section call_test vstart=0x900
    ; 强制用near转移short地址结果只是jmp语句总长度改变
    ; 由原来的2字变为了3字，地址 0x7F 变为了 0x007F
    jmp near start
times 127 db 0
start:
    mov ax,0x1234
    jmp $