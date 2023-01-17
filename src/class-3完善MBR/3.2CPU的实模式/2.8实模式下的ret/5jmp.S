; 间接绝对远转移
section call_test vstart=0x900
    ; jmp far 0:start
    jmp far [addr]
times 128 db 0
; 偏移地址在前
addr dw start,0
start:
    mov ax,0x1234
    jmp $
