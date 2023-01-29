%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
    ; 初始化吸显卡文本模式段地址
    mov ax,0xb800
    mov gs,ax; gs存储段地址
    
    ; 将背景绿色，前景红色，跳动的"1 MBR"写入显存
    .print_1_MBR:
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