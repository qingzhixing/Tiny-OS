%include "include.S"
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

    mov eax,LOADER_START_SECTOR     ; loader起始扇区LBA地址
    mov bx,LOADER_BASE_ADDR         ; loader写入内存的地址
    mov cx,LOADER_SECTOR_SIZE       ; 待读入扇区的数量:LOADER_SECTOR_SIZE(=4)*512 byte
    call rd_disk_m_16

    jmp LOADER_BASE_ADDR


    ; 在16位模式下读取硬盘n个扇区
    ; eax=LBA扇区号
    ; bx=将数据写入的内存地址
    ; cx=读入的扇区数
    rd_disk_m_16:
        ; 数据预处理
        mov esi,eax     ; 备份eax,源变址寄存器
        mov di,cx       ; 备份cx,读取扇区数

        ; 第一步：设置要读写的扇区数量
        .step_1:
            mov dx,0x1f2    ; 调用端口号，写操作为设置Primary通道的读取扇区数量
            mov al,cl
            out dx,al       ; 写操作为设置Primary通道的读取扇区数量

            mov eax,esi     ; 恢复ax

        ; 第二步：将LBA地址存入 0x1f3 ~ 0x1f6 端口
        .step_2:
            ; LBA地址7~0位存入0x1f3端口
            mov dx,0x1f3
            out dx,al

            ; LBA地址15~8位写入0x1f4端口
            mov cl,8
            shr eax,cl      ; 右移8位
            mov dx,0x1f4
            out dx,al

            ; LBA地址23~16位写入0x1f5端口
            shr eax,cl      ; 再次右移8位，一共右移16位
            mov dx,0x1f5
            out dx,al

            ; 将LBA地址24~27位写入0x1f6端口，设置属性
            shr eax,cl      ; 再次右移8位，一共右移24位
            and al,0x0f     ; 将24~27位清零
            or al,0xe0      ; 设置27~24位为1110,表示LBA模式，使用主盘
            mov dx,0x1f6
            out dx,al

        ; 第三步，向0x1f7写入读命令：0x20
        .step_3:
            ; 0x1f7端口写操作表示命令字，读表示硬盘状态
            mov dx,0x1f7
            mov al,0x20
            ; 写入命令字
            out dx,al

        ; 第四步：检测硬盘状态
        .step_4:
            .not_ready:
                ; sleep some time
                nop
                ; 读操作时寄存器在前
                in al,dx
                and al,0x88         ; 第3位为1表示硬盘控制器已经准备好数据传输
                                    ; 第7位为1表示正在繁忙
                                    ; 这里我们只需要这两位，所以将其单独取出
                cmp al,0x08         ; 准备好且不繁忙jne则为0
                                    ; 繁忙时其他位均无效
                jne .not_ready      ; 未准备好则继续等待

            ; 第五步：从0x1f6端口中读取数据
            ; 数据预处理
            mov ax,di               ; 读取扇区数
            mov dx,256
            mul dx                  ; ax*=dx,即ax=di*256(结果为32位，此时只用到了低16位结果)
            mov cx,ax               ; 乘积转移到cx中,作为循环计数器
            ; di为读取扇区数，一个扇区512字节，每次读入一个字(此时在16位系统，所以为16位,2字节)
            ; 共需 di* [512字节/(1字=2字节)]，所以di*256
            mov dx,0x1f0

            .go_on_read:
                in ax,dx            ; 一次读2字节,16位
                mov [bx],ax
                add bx,2            ; 将ax放入[bx],并移动bx指针位置
                loop .go_on_read    ; cx为循环计数器

        ret

    times 510-($-$$) db 0; 填充0到510字节处
    db 0x55,0xaa; 魔数,用于判断mbr分区是否损坏