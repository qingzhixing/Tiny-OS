TI_GDT equ 0
RPL0 equ 0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0
put_int_hex_buffer dq 0         ; 定义8字节缓冲区用于数字到字符的转换

[bits 32]
section .text
    ; (cdecl)put_char:将栈中一个字符(uint8_t)写入光标所在处
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
        mov cl,[esp+36]     ; pushad:32byte + 主调函数返回地址:4byte = 36
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

    ; (cdecl)put_str通过put_char打印以\0结尾的字符串(uint8_t*)
    global put_str
    put_str:
        ;备份用到的寄存器
        push ebx
        push ecx
        or ecx,ecx          ; 用ecx存储传递给put_char的函数
        mov ebx,[esp+12]    ; 获取待打印字符串地址
                            ; 2个寄存器1个主调函数返回地址共12字节
        
        .go_on_print:
            mov cl,[ebx]
            cmp cl,0        ; \0字符串结束
            je .str_over

            push ecx        ; TODO:push cl会报错，为什么？
            call put_char
            add esp,4       ; 回收栈空间,符合cdecl标准
            inc ebx         ; 使ebx指向下一个字符
            jmp .go_on_print

        .str_over:
            ; 恢复寄存器
            pop ecx
            pop ebx

            ret

    ; 将小端字节序的数字变成对应ASCII后，倒置
    ; 输入：栈中参数为待打印数字(32位)
    ; 输出：在屏幕上打印16进制数字，并且不会打印前置0x
    global put_int_hex
    put_int_hex:
        pushad
        mov ebp,esp         ; 这里不直接使用esp来寻址，养成好习惯，防止不经意的栈操作改变esp
        mov eax,[ebp+36]    ; pushad:32+返回地址4=36
        mov edx,eax         ; eax为参数备份，edx是参与每次数位转换的寄存器
        mov edi,7           ; 指定该位数字在buffer中的偏移
                            ; 由于是小端字节序，最前面的数字是最低位
        mov ecx,8           ; 32位数字中，16进制数字有8个
        mov ebx,put_int_hex_buffer

        ; 将32位数字从低位往高位逐个处理
        .16based_4bits:     ; 每4位2进制数为1个16进制数字
            and edx,0x0000_000F     ;解析16位数字的每一位
                                    ; and操作后，edx只有最低4位有效
            cmp edx,9   ; 0~9和A~F要分别处理
            jg .is_AtoF ; A~F
            add edx,'0' ; 0~9
            jmp .store

            .is_AtoF:
                sub edx,10
                add edx,'A'

            ; 将每一位数字转换成对应字符后，按照类似大端字节序储存到buffer
            .store:
                mov [ebx+edi],dl    ; dl为对应ASCII码
                dec edi
                shr eax,4
                mov edx,eax
                loop .16based_4bits
        inc edi     ; edi多减了一次，加回来

        ; 打印之前把高位连续字符去掉：如00123 to 123
        .ready_to_print:
            .skip_prefix_0:
                cmp edi,8       ;已经比较到第9个字符，比较完了
                je .full_0

                mov cl,[put_int_hex_buffer+edi]
                inc edi
                cmp cl,'0'
                je .skip_prefix_0   ; 是 0 则继续跳过
                ; edi在上面指向了下一个字符，需要恢复
                dec edi
                jmp .put_each_num
            
            ; 全0则只打印0
            .full_0:
                mov cl,'0'
            
            .put_each_num:
                push ecx        ; cl为待打印字符
                call put_char
                add esp,4       ; 恢复栈
                inc edi
                mov cl,[put_int_hex_buffer+edi]
                
                cmp edi,8       ; 没打印完则继续打印
                jl .put_each_num

        popad
        ret