%include "boot.inc"
; defs:
;     ; 配置文件
;     LOADER_BASE_ADDR equ 0x900   ; loader在内存中的位置，由mbr放入
;     LOADER_START_SECTOR equ 0x2     ; loader在硬盘上的逻辑扇区地址，即LBA地址，
;                                     ; 放在第二块（从0开始）扇区

;     ; gdt描述符属性
;     DESC_G_4K   equ	  1_000_0000_0000_0000_0000_0000b   ;  描述符G位粒度，为4KB
;     DESC_D_32   equ	   1_00_0000_0000_0000_0000_0000b   ;  操作数为32位
;     DESC_L	    equ	    0_0_0000_0000_0000_0000_0000b   ;  64位代码标记，0为使用32位代码段，目前属于保留位
;     DESC_AVL    equ	      0_0000_0000_0000_0000_0000b	;  此位无意义，留给操作系统用的，暂置为0
;     DESC_P	    equ		           1_000000000000000b   ; 段存在标记，供cpu检查，1则为存在
;     DESC_DPL_0  equ		            00_0000000000000b   ; 特权级为0,最高特权级
;     DESC_DPL_1  equ		            01_0000000000000b   ; 特权级1
;     DESC_DPL_2  equ		            10_0000000000000b   ; 特权级2
;     DESC_DPL_3  equ		            11_0000000000000b   ; 特权级3
;     DESC_S_sys  equ		              0_000000000000b   ; 系统段S位

;     DESC_EMPTY_LOW4  equ 0x0000_0000
;     DESC_EMPTY_HIGH4 equ 0x000_00000


;     ; 代码段GDT:
;     DESC_BASE_CODE3     equ 0x00                            ; 段基址31~24位:第三部分
;     DESC_BASE_CODE2     equ 0x00                            ; 段基址23~16位，第二部分
;     DESC_BASE_CODE1     equ 0x0000                          ; 段基址15~0位，第一部分，平坦模式下段基址为0

;     DESC_LIMIT_CODE2    equ 1111_0000_0000_0000_0000b       ; 代码段段界限19~16位,第二部分
;     DESC_LIMIT_CODE1    equ 0xFFFF                          ; 代码段界限15~0位，第一部分
;                                                             ;  与第一部分将组成20个二进制1即0xFFFFF

;     DESC_S_CODE equ		     1_000000000000b                ; S位为1表示为普通内存段,非系统段

;     DESC_TYPE_CODE  equ	      1000_00000000b	            ; x=1,c=0,r=0,a=0 代码段是
;                                                             ;  可执行的,非依从的,不可读的,已访问位a清0.  

;     ; 代码段gdt低32位即低4字节
;     DESC_CODE_LOW4 equ (DESC_BASE_CODE1<<16)+DESC_LIMIT_CODE1

;     ; 代码段gdt高32位即高4字节
;     DESC_CODE_HIGH4 equ (DESC_BASE_CODE3 << 24) + DESC_G_4K + DESC_D_32 +\
;         DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P +\
;         DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + DESC_BASE_CODE2
;     ; 0x00<<24 : 31~24位为段基址第三部分. 其次是G位, D/B, L, AVL, 段界限2,
;     ; P, DPL, S, TYPE, 段基址第二部分.


;     ; 数据段GDT
;     DESC_BASE_DATA3     equ DESC_BASE_CODE3                 ; 段基址31~24位:第三部分
;     DESC_BASE_DATA2     equ DESC_BASE_CODE2                 ; 段基址23~16位，第二部分
;     DESC_BASE_DATA1     equ DESC_BASE_CODE1                 ; 段基址15~0位，第一部分，平坦模式下段基址为0

;     DESC_LIMIT_DATA2  equ DESC_LIMIT_CODE2                  ; 同 DESC_LIMIT_CODE2
;     DESC_LIMIT_DATA1  equ DESC_LIMIT_CODE1

;     DESC_S_DATA equ	  DESC_S_CODE                           ; 普通数据段，非系统段

;     DESC_TYPE_DATA  equ	      0010_00000000b	            ; x=0,e=0,w=1,a=0 数据段是
;                                                             ;  不可执行的,向上扩展的,可写的,已访问位a清0.

;     ; 数据段gdt低32位
;     DESC_DATA_LOW4 equ (DESC_BASE_DATA1<<16)+DESC_LIMIT_DATA1
;     ; 数据段gdt高32位
;     DESC_DATA_HIGH4 equ (DESC_BASE_DATA3 << 24) + DESC_G_4K + DESC_D_32 +\
;         DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P +\
;         DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + DESC_BASE_DATA2


;     ; 显存段GDT
;     DESC_BASE_VIDEO3     equ 0x00
;     DESC_BASE_VIDEO2     equ 0x0b
;     DESC_BASE_VIDEO1     equ 0x8000
;     ; 段基址为显存文本模式段地址:0xb8000

;     DESC_LIMIT_VIDEO2   equ 0000_000000000000000b           ; 显存段描述符段界限
;     DESC_LIMIT_VIDEO1   equ 0x7                             ; limit = (0xbffff-0xb8000)/4k = 0x7
;                                                             ; (0x0~0x7)*4k=32字节表示显卡
;                                                             ; 文本模式0xb80000~0xbffff共32字节

;     DESC_TYPE_VIDEO     equ DESC_TYPE_DATA

;     ; 显存段gdt低32位
;     DESC_VIDEO_LOW4 equ (DESC_BASE_VIDEO1<<16)+DESC_LIMIT_DATA1
;     ; 显存段gdt高32位
;     DESC_VIDEO_HIGH4 equ (DESC_BASE_VIDEO3 << 24) + DESC_G_4K + DESC_D_32 +\
;         DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P +\
;         DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + DESC_BASE_VIDEO2

;     ; 选择子属性
;     ; 请求特权级:0,1,2,3
;     RPL0  equ   00b
;     RPL1  equ   01b
;     RPL2  equ   10b
;     RPL3  equ   11b
;     TI_GDT	 equ   000b
;     TI_LDT	 equ   100b

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

        jmp dword SELECTOR_CODE:p_mode_start    ; 刷新流水线


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