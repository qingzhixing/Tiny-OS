[bits 16]
mov word [bx],0x1234
mov word [eax],0x1234   ; 寻址寄存器从16位变成32位，故需要0x67寻址方式反转前缀
mov dword [eax],0x1234  ; 不仅寄存器反转，操作数也反转为了32位，
                        ;   故需要0x67和0x66操作数反转前缀
[bits 32]
mov dword [eax],0x1234
mov word [eax],0x1234
mov dword [bx],0x1234