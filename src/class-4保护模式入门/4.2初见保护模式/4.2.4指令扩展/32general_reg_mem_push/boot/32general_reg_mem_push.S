%include "boot.inc"
section push32_test vstart=0x900 ; LOADER_BASE_ADDR
    jmp loader_start

    gdt_addr:
        ; 构建gdt及其内部的描述符
        GDT_BASE:   dd 0x00000000
                    dd 0x00000000
        
        CODE_DESC:  dd 0x0000FFFF
                    dd DESC_CODE_HIGH4

        DATA_STACK_DESC:    dd 0x80000008
                            dd DESC_DATA_HIGH4  ; 此时 dpl 已改为 0

        GDT_SIZE equ $ - GDT_BASE
        GDT_LIMIT equ GDT_SIZE-1
        SELECTOR_CODE equ (0x001<<3) + TI_GDT + RPL0
        SELECTOR_DATA equ (0x002<<3) + TI_GDT + RPL0
        SELECTOR_VIDEO equ (0x003<<3) + TI_GDT + RPL0

        gdt_ptr:    dw GDT_LIMIT
                    dd gdt_addr

    ; 进入保护模式:
    ; 1.打开 A20
    ; 2.加载 gdt
    ; 3.将 cr0 的 pe位 置为 1
    loader_start:
        ; 打开A20
        in al,0x92
        or al,0000_0010B
        out 0x92,al

        ;加载gdt
        lgdt [gdt_ptr]

        ;将 cr0 的 pe位 置为 1
        mov eax,cr0
        or eax,0x00000001
        mov cr0,eax

        ;刷新流水线，避免分支预测的影响，这种CPU优化策略最怕jmp跳转
        ;这将之前做的预测失效，从而起到了刷新的作用
        jmp SELECTOR_CODE:p_mode_start

[bits 32]
p_mode_start:
    mov ax,SELECTOR_DATA
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,0x900
    ; 请关注下面几行代码，上面的代码无需关注，后续书中会讲解
    ; 测试寄存器入栈
    push ax                 ; 2字节
    push eax                ; 4字节
    ; 测试内存入栈
    push word [0x1234]      ; 2字节
    push dword [0x1234]     ; 4字节
    jmp $