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
        mov bx,ax   ; bx此时表示光标在第几个字符，但由于一个字符占2字节
                    ; 故实际使用时要将 bx * 2获取字符显存地址

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
        .is_line_feed:          ; 我们这里将LF和CR都处理为换行
            .move_cursor_line_head:
                xor dx,dx           ; 被除数高16位
                mov ax,bx           ; 被除数低16位
                mov si,80           ; 除数

                div si

                sub bx,dx           ; dx为余数，bx-bx%80即为bx向整80倍取整
            .move_cursor_next_line:
                add bx,80
                cmp bx,2000
                jnl .roll_screen
            call .set_cursor
            jmp .put_char_done

        .is_backspace:
            dec bx      ; 将光标移动到待删除字符上(光标原本在字符后)
            shl bx,1    ; bx转化为显存中字符的地址
            
            mov byte [gs:bx], 0x20  ; 将字符替换为空格
            inc bx  ; bx此时为属性位
            mov byte [gs:bx],0x07   ; 黑屏白字
            
            shr bx,1    ; 显存地址转化为光标位置

            call .set_cursor
            jmp .put_char_done

        .put_other:
            shl bx,1
            
            mov [gs:bx],cl          ; 放置字符
            inc bx
            mov byte [gs:bx],0x07   ; 黑底白字

            shr bx,1
            inc bx

            cmp bx,2000             ;一个页面只能容纳2000个字符(0~1999)
            jnl .roll_screen
            call .set_cursor
            jmp .put_char_done

        .set_cursor:
            ; 设置高8位
            mov dx,0x03d4   ; Address Register
            mov al,0x0e     ; Cursor Location High Register
            out dx,al
            mov dx,0x03d5   ; Data Address
            mov al,bh
            out dx,al

            ; 设置低8位
            mov dx,0x03d4
            mov al,0x0f     ; Cursor Location Low Register
            out dx,al
            mov dx,0x03d5
            mov al,bl
            out dx,al
            
            ret

        .roll_screen:
            ; 1~24行复制到0~23行
            cld                     ; 清除方向位，为movsd做准备
            mov ecx,960             ; 搬运次数(2000-80)字符 *
                                    ; 每个字符占2字节（本身字符+属性) /
                                    ; 一次搬运4字节 = 960次
            mov esi,0xc00b80a0      ; 第1行行首
            mov edi,0xc00b8000      ; 第0行行首
            rep movsd

            ; 再填充24行为空格
                mov ebx,3840        ; 最后一行第一个字节偏移=1920*2
                mov ecx,80          ; 一行80字符(160字节），每次清空1个字符

            .clear_single_char:
                mov word[gs:ebx],0x0720 ; 黑底白字的空格
                add ebx,2
                loop .clear_single_char
            
            mov bx,1920        ; 将光标置于最后一行首字符
            call .set_cursor

            jmp .put_char_done
        .put_char_done:
            popad
            ret
