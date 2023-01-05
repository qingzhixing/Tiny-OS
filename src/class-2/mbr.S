SECTION MBR vstart=0x7c00; 程序在内存中地址为0X7C00
    ; 清空寄存器
    mov ax,0
    ; cs值不需要改动，为代码段寄存器
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax

    mov sp,0x7c00; 初始化栈指针

    ; 清屏
    .clear_screen:
        ; 利用0x10中断 0x06子功能,上卷全部行，即可实现清屏
        mov ax,0x600    ; AH:功能号=0x06, AL:上卷行数(为0则表示全部)=0
        mov bx,0x700    ; BH:上卷行属性,颜色等=0x07
        mov cx,0        ; (CL,CH)表示窗口左上角(X,Y)位置，为(0,0)
        mov dx,0x184f   ; (DL,DH)表示窗口右下角(X,Y)位置,为(79,24)
                        ; 下标从0开始,0x18=24,0x4f=79.
                        ; VGA文本模式中，一行只能容纳80个字符，共25行
        int 0x10        ; 调用中断
    
    ; 获取光标位置
    .get_cursor:
        mov ah,0x3      ; 表示调用子功能编号，0x3号子功能是获取光标位置
        mov bh,0        ; bh寄存器储存的是带获取光标的页号
                        ; TODO:光标还分页吗？怎么回事？
        int 0x10        ; 调用中断，输出:ch=光标开始行, cl=光标结束行
                        ; dh=光标所在行号, dl=光标所在列号

    ; 调用0x10中断13号子功能打印字符串
    .print:
        mov ax,message
        mov bp,ax       ; es:bp为字符串首的地址,es此时因为初始化等于0

        ; 光标位置仅使用dx值,cx值可忽略
        mov cx,7        ; cx为字符串长度,不包括\0
        mov ax,0x1301   ; 子功能号13显示字符以及显示属性
                        ; al:写字符方式=0x01 表示作为字符串显示，光标跟随移动到新的位置
        mov bx,0x2      ; bh:要显示的页号=0, bl:字符属性=0x02 黑底绿字

        int 0x10        ; 执行BIOS 0x10号中断

    jmp $; 阻塞

    message db "QZX MBR"
    times 510-($-$$) db 0; 填充0到510字节处
    db 0x55,0xaa; 魔数,用于判断mbr分区是否损坏