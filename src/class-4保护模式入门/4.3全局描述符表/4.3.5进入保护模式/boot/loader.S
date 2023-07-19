%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
    LOADER_STACK_TOP equ LOADER_BASE_ADDR
    jmp loader_start

    ; 构建gdt及其内部的描述符
    ; GDT起始地址:GDT_BASE
    ; 0号GDT
    GDT_BASE:           dd DESC_EMPTY_LOW4      ; dd为定义双字节变量伪指令
                        dd DESC_EMPTY_HIGH4
    ; 1号GDT:CODE_DESC
    CODE_DESC:          dd DESC_CODE_LOW4
                        dd DESC_CODE_HIGH4
    ; 2号GDT:DATA_STACK_DESC
    DATA_STACK_DESC:    dd DESC_DATA_LOW4
                        dd DESC_DATA_HIGH4
    ; 3号GDT:VIDEO_DESC 显存段描述符
    VIDEO_DESC:         dd DESC_VIDEO_LOW4
                        dd DESC_VIDEO_HIGH4     ; 此时dpl为0

    GDT_SIZE equ $ - GDT_BASE
    GDT_LIMIT equ GDT_SIZE - 1

    times 59 dq 0   ; 预留59个描述符空位，为了方便扩展，dq定义8字节变量

    times 5 db 0    ; 这里用来对齐512Byte(0x200)
                    ; jmp - 3Byte
                    ; 4 GDT - 4*8=32Byte
                    ; times 59* (dq) 8
                    ; times 5 db - 5
                    ; 一共512Byte=0x200B

    ; 定义选择子
    ; CODE为1号GDT
    SELECTOR_CODE equ (0x0001<<3)+TI_GDT+RPL0
    ; DATA为2号GDT
    SELECTOR_DATA equ (0x0002<<3)+TI_GDT+RPL0
    ; VIDEO为3号GDT
    SELECTOR_VIDEO equ (0x0003<<3)+TI_GDT+RPL0

    ; gdt指针,前2字节为GDT界限，后4字节为GDT起始地址
    gdt_ptr dw GDT_LIMIT
            dd GDT_BASE
    
    loadermsg db "To loader in real."

    loader_start:
        ; 进入保护模式前在实模式下打印字符串:
        .print_loader_msg_real:
            ; 利用0x10中断13号功能打印字符串
            mov sp,LOADER_BASE_ADDR
            mov bp,loadermsg            ; ES:BP = 字符串地址
            mov cx,18                   ; 字符串长度
            mov ax,0x1301               ; 13号功能，1号输出方式：作为字符串输出并移动光标
            mov bx,0x001c               ; 在第0页打印，蓝底粉红字(BL=0x1c)
            mov dx,0x1800               ; (DH,DL)坐标(行,列)
            int 0x10

        ; 进入保护模式准备：
        ; 1.打开A20Gate
        ; 2.加载gdt
        ; 3.将cr0的PE位设为1
        .open_A20Gate:
            in al,0x92
            or al,0000_0010b
            out 0x92,al

        .load_gdt:
            lgdt [gdt_ptr]

        .set_cr0_pe_1:
            mov eax,cr0
            or eax,0x00000001
            mov cr0,eax

        jmp dword SELECTOR_CODE:p_mode_start    ; 用无条件跳转指令清空cpu流水线指令缓存


    [bits 32] ; 32位模式
    p_mode_start:
        ; 初始化段寄存器
        mov ax,SELECTOR_DATA
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov esp,LOADER_STACK_TOP
        mov ax,SELECTOR_VIDEO
        mov gs,ax

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