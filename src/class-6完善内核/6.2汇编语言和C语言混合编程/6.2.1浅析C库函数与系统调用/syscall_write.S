[bits 32]
section .data
    str_c_lib: dw "c library says: Hello World!!!",0xa  ;0xa为LF换行 ASCII码
    str_c_lib_len equ $-str_c_lib       ; 31 0x1f

    str_syscall: dw "syscall says: Hello World!",0xa
    str_syscall_len equ $-str_syscall

section .text
    global _start
    _start:
        ; ---------- 模拟C语言中系统调用库函数write ----------
        push str_c_lib_len  ; 按照c调用约定压入参数
        push str_c_lib
        push 1              ; 按照C约定从右往左入栈

        call simu_write
        add esp,12          ; 调用者清栈

        ; ---------- 直接使用系统中断进行系统调用(Linux平台）----------
        mov eax,4   ; 0x80第4号子功能是write系统调用（非C库函数write)
        mov ebx,1
        mov ecx,str_syscall
        mov edx,str_syscall_len ; 参数从ebx起依次写入对应寄存器

        int 0x80    ; 发起中断，通知Linux完成请求功能n

        ; ---------- 退出程序 ----------
        mov eax,1   ; 1号子功能是exit
        mov ebx,0
        int 0x80

    ; 模拟C库函数调用write系统调用
    simu_write:
        push ebp            ; 备份ebp
        mov ebp,esp
        mov eax,4           ; 第4号子功能是write系统调用（非C库函数write)
                            ; TODO:为何函数地址和ebp总共占用16Byte?是64位下运行32位的缘故吗？
        mov ebx,[ebp+16]     ; 第一个参数
        mov ecx,[ebp+24]    ; 第二个参数
        mov dx,[ebp+32]    ; 第三个参数

        int 0x80

        mov esp,ebp         ; 防止在函数内部push，此处可以删去，无实际作用
        pop ebp             ; 恢复ebp
        ret