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

    ; 用于保存内存容量,以字节为单位
    ; 当前偏移loader.bin文件头0x200字节
    ; loader.bin在内存中的地址为LOADER_BASE_ADDR=0x900
    ; 则total_mem_bytes内存中地址为0xb00
    ; 在内核中会引用此地址
    total_mem_bytes dd 0

    ; gdt指针,前2字节为GDT界限，后4字节为GDT起始地址
    gdt_ptr dw GDT_LIMIT
            dd GDT_BASE

    ; 人工对齐256Bytes:
    ; total_mem_bytes:4 + gdt_ptr:6 + ards_buf:244 + ards_nr:2 一共256Bytes

    ards_buf times 244 db 0
    ARDS_SIZE_BYTES equ 20
    ards_nr dw 0                ; 用于记录ARDS结构体的数量

    ; 定义选择子
    ; CODE为1号GDT
    SELECTOR_CODE equ (0x0001<<3)+TI_GDT+RPL0
    ; DATA为2号GDT
    SELECTOR_DATA equ (0x0002<<3)+TI_GDT+RPL0
    ; VIDEO为3号GDT
    SELECTOR_VIDEO equ (0x0003<<3)+TI_GDT+RPL0
    
    loadermsg db "To loader in real."

    initial_mem_size_errormsg db "FAILED TO INITIALIZE MEMORY SIZE!!!"

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

        ; 报错测试
        ; jmp .error_hlt

        .initial_mem_size:
            ; 我们规定，最终内存大小存入edx中，单位为Byte
            mov edx,0x534d4150      ; "SMAP" 用于信息校验
            .try_0xe820:
                ; 0xe820方法
                xor ebx,ebx             ; 调用前需清零
                mov di,ards_buf         ; ARDS缓冲区，BIOS将写入di指向的内存，以ARDS格式返回
                
                .e820_mem_get_loop:
                    ; mov eax,0x0000e820
                    mov ax,0xe820       ; 功能号,执行完int 0x15后变为0x 534d4150
                                        ;   故每次执行int前都要更新子功能号
                    mov cx,ARDS_SIZE_BYTES           ; ARDS地址范围描述符结构大小为20字节
                    int 0x15
                    ; CF位为1则表示有错误发生，尝试0xe801子功能
                    jc .e820_failed_so_try_e801

                    add di,cx           ; 移动di指向新ARDS结构位置
                    inc word [ards_nr]  ; ARDS数量增加
                    cmp ebx,0           ; 若 ebx==0 && cf !=1 则表示ards全部返回
                    ; 否则继续循环
                    jne .e820_mem_get_loop
                
                ; 在所有ards结构中找到内存容量(即base_addr_low+length_low)最大值，则为可用内存容量
                mov cx,[ards_nr]
                mov ebx,ards_buf        ; 遍历ards_buf
                xor edx,edx             ; edx为最大容量，清空
                .find_max_mem_area:
                    mov eax,[ebx]       ; base_addr_low
                    add eax,[ebx+8]     ; length_low
                    add ebx,ARDS_SIZE_BYTES ; 遍历到下一个ards
                    cmp edx,eax         ; edx为最大内存大小
                    ; edx大于等于eax则eax不是最大值
                    jge .next_ards
                    ; 否则更新edx为eax
                    mov edx,eax
                .next_ards:
                    loop .find_max_mem_area
                
                jmp .mem_get_ok

            ; e820错误后调用
            ; 调用0x15号中断，ax=E801h号子方法获取内存大小（最大4G）
            ; 返回值：  
            ;   ax,cx值相同，以KB为单位
            ;   bx,dx值相同，以64KB为单位
            ; 注意:
            ;   ax,cx中为低16MB（只显示15MB以下的内存容量)
            ;   bx,dx中为16MB~4GB
            .e820_failed_so_try_e801:
                mov ax,0xe801
                int 0x15
                ; CF位为1则出错，使用下一种方法
                jc .e801_failed_so_try_88
                ;否则继续

                .handle_low_16MB:
                    ;ax,cx单位为KByte，先转化为Byte为单位
                    mov cx,0x400    ;此时cx为乘数:0x400 = 1024
                    mul cx          ; mul默认乘数寄存器为ax
                                    ; 结果低16位:AX,高16位:DX
                    ; 现在将ax,dx数据统一放入edx中
                    shl edx,16          ;左移16位
                    and eax,0x0000FFFF  ; 清空eax高16位以便下面的or运算
                    or edx,eax
                    add edx,0x100000    ; edx加上16MB中最后的1MB(0x100000B=1MB)
                    mov esi,edx         ; 后面乘法会破坏edx，故先备份
                .handle_16MB_to_4GB:
                    ;将16MB以上的内存转化为byte单位
                    xor eax,eax         ; 清空eax
                    mov ax,bx           ; 将bx放入默认乘数寄存器
                    mov ecx,0x10000     ; 0x10000 Byte = 64KB
                    mul ecx
                    add esi,eax         ; 累加
                    ; 最大4GB，故乘积用32位eax足够了
                    mov edx,esi         ; edx为最大内存大小
                    jmp .mem_get_ok
            
            ; int 15h ah=0x88 只能获取64MB之内的内存
            ; 0x88子功能号只会返回1MB以上的内存
            .e801_failed_so_try_88:
                mov ah,0x88
                int 0x15
                ;出错则挂起
                jc .error_hlt
                ; 将单位变为Byte(同上)
                and eax,0x0000FFFF
                mov cx,0x400
                mul cx
                ; 将低16位ax和高16位dx放入edx
                shl edx,16
                or edx,eax

                add edx,0x100000    ;加上最开始的1MB
            
            ; 我滴任务完成辣!
            .mem_get_ok:
                xchg bx,bx      ;debug 用来查看edx的值，看是否内存检测成功
                mov [total_mem_bytes],edx


        
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

; 无法获取内存则报错挂起
    .error_hlt:
        ; 此时还在实模式，我们用实模式的打印字符串方式
        .print_error:
        ; 利用0x10中断13号功能打印字符串
            mov sp,LOADER_BASE_ADDR
            mov bp,initial_mem_size_errormsg    ; ES:BP = 字符串地址
            mov cx,35                           ; 字符串长度
            mov ax,0x1301                       ; 13号功能，1号输出方式：作为字符串输出并移动光标
            mov bx,0x001c                       ; 在第0页打印，蓝底粉红字(BL=0x1c)
            mov dx,0x0200                       ; (DH,DL)坐标(行,列)
            int 0x10
        hlt     ;挂起


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
    xchg bx,bx      ;阻塞前魔术断点
    jmp $; 阻塞