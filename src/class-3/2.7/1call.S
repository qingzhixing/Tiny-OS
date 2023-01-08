call near near_proc
jmp $
addr dd 4
near_proc:
    mov ax,0x1234
    ret