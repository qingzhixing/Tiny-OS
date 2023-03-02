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

    times 60 dq 0; 预留60个描述符空位，为了方便扩展，dq定义8字节变量

    ; 用于保存内存容量,以字节为单位
    ; 当前偏移loader.bin文件头0x200字节
    ; loader.bin在内存中的地址为LOADER_BASE_ADDR=0x900
    ; 则total_mem_bytes内存中地址为0xb00
    ; 在内核中会引用此地址
    ; TODO: 为何为偏移200? 定义三个GDT不占用内存？
    ; TODO: 不应该是60字节+3个gdt的大小位偏移量吗，为什么只有times的60个字节？
    total_mem_bytes dd 0

    ; gdt指针,前2字节为GDT界限，后4字节为GDT起始地址
    gdt_ptr dw GDT_LIMIT
            dd GDT_BASE

    ; 人工对齐256Bytes:
    ; total_mem_bytes:4 + gdt_ptr:6 + ards_buf:244 + ards_nr:2 一共256Bytes

    ards_buf times 244 db 0
    ards_nr dw 0                ; 用于记录ARDS结构体的数量

    ; 定义选择子
    ; CODE为1号GDT
    SELECTOR_CODE equ (0x0001<<3)+TI_GDT+RPL0
    ; DATA为2号GDT
    SELECTOR_DATA equ (0x0002<<3)+TI_GDT+RPL0
    ; VIDEO为3号GDT
    SELECTOR_VIDEO equ (0x0003<<3)+TI_GDT+RPL0
    
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

        .initial_mem_size:
            ; 0xe820方法
            xor ebx,ebx             ; 调用前需清零
            mov edx,0x534d4150      ; "SMAP" 用于信息校验
            mov di,ards_buf         ; ARDS缓冲区，BIOS将写入di指向的内存，以ARDS格式返回
            
            .e820_mem_get_loop:
                ; mov eax,0x0000e820
                mov ax,0xe820       ; 功能号,执行完int 0x15后变为0x 534d4150
                                    ;   故每次执行int 前都要更新子功能号
                mov cx,20           ; ARDS地址范围描述符结构大小为20字节
                int 0x15
                ; CF位为1则表示有错误发生，尝试0xe801子功能
                jc .e820_failed_so_try_e801

                add di,cx           ; 移动di指向新ARDS结构位置
                inc word [ards_nr]  ; ARDS数量增加
                cmp ebx,0           ; 若 ebx==0 && cf !=1 则表示ards全部返回
                ; 否则继续循环
                jne .e820_mem_get_loop
            
            ; 在所有ards结构中找到内存容量(即base_add_low+length_low)最大值，则为可用内存容量
            mov cx,[ards_nr]
            ; TODO:止步于此，明日继续

            ; e820错误后调用
            .e820_failed_so_try_e801:
        
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