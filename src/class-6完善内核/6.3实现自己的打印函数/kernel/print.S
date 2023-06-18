TI_GDT equ 0
RPL0 equ 0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

[bits 32]
section .text
    ; put_char:将栈中一个字符写入光标所在处
    global put_char ; 使外部可见
    put_char:
        pushad          ; 备份所有寄存器(懒得一个一个push了)
        ; 为了保险起见每次都更新gs为正确视频段选择子，防止cpu清空gs
        mov ax,SELECTOR_VIDEO
        mov gs,ax       ; 不能直接写段寄存器

        ; 获取光标位置
        ; 获取高8位
        mov dx,0x03d4   ; 索引寄存器 CRT Controller-Address Register
        mov al,0x0e     ; Cursor Location High Register
        out dx,al       ; 将al数据写入dx端口
        mov dx,0x03d5   ; Data Register
        in al,dx        ; 从dx端口读数据写入al
                        ; 当源操作数是8位寄存器，目标操作数必须是al
        mov ah,al       ; 将得到的高8位坐标移动到高位置

        ; 获取低8位
        mov dx,0x03d4
        mov al,0x0f     ; Cursor Location Low Register
        out dx,al
        mov dx,0x03d5
        in al,dx

        ; 将光标坐标存入bx
        mov bx,ax

        ; 从栈中获取待打印的字符
        mov ecx,[esp+36]    ;pushad:32byte + 主调函数返回地址:4byte = 36
        cmp cl,0xd          ; CR控制字符
        je .is_carriage_return
        cmp cl,0xa          ; LF换行符
        je .is_line_feed
        cmp cl,0x8          ; BS(backspace)
        je .is_backspace
        jmp .put_other

        .is_carriage_return:

        .is_line_feed:

        .is_backspace:
            
        .put_other: