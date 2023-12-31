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

    mov si,happyNewYear

    call Print


    jmp $; 阻塞

    ; 打印字符串
    ; 调用方法: 将字符串地址存入 si
    Print:
        mov ah,0x0e
        .Loop:
            mov al,[si]
            cmp al,0
            je .Done

            int 0x10
            inc si
            
            jmp .Loop
        .Done:
            ret
    
    happyNewYear db "Happy New Year!",10,13,0
    times 510-($-$$) db 0; 填充0到510字节处
    db 0x55,0xaa; 魔数,用于判断mbr分区是否损坏