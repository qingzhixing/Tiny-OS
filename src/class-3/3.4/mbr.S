SECTION MBR vstart=0x7c00; 程序在内存中地址为0X7C00
    ; 清空寄存器
    mov ax,0
    ; cs值不需要改动，为代码段寄存器
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax

    mov sp,0x7c00; 初始化栈指针

    ; 初始化吸显卡文本模式段地址
    mov ax,0xb800
    mov gs,ax; gs存储段地址

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

    ; 将背景绿色，前景红色，跳动的"1 MBR"写入显存
    .print:
        mov byte [gs:0x00],'1'
        mov byte [gs:0x01],0xA4; A表示绿色背景闪烁，4表示前景色为红色

        mov byte [gs:0x02],' '
        mov byte [gs:0x03],0xA4

        mov byte [gs:0x04],'M'
        mov byte [gs:0x05],0xA4

        mov byte [gs:0x06],'B'
        mov byte [gs:0x07],0xA4
        
        mov byte [gs:0x08],'R'
        mov byte [gs:0x09],0xA4

    jmp $; 阻塞
    times 510-($-$$) db 0; 填充0到510字节处
    db 0x55,0xaa; 魔数,用于判断mbr分区是否损坏