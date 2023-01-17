; 间接绝对短转移-内存寻址
section call_test vstart=0x900
    ; 将start地址存入ds:addr中
    ; 这里的word修饰的是addr地址不跨段
    ; 是指进行不跨段的相对近转移

    mov word [addr], start
    jmp near [addr]
times 128 db 0
; addr地址为word,addr储存的数据为dword
addr dw 0
start:
    mov ax,0x1234
    jmp $
