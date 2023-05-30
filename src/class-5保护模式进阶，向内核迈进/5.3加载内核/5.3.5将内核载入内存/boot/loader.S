%include "include.S"

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

        ; 内存检测
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
                ; xchg bx,bx      ;debug 用来查看edx的值，看是否内存检测成功
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
    ;创建页目录及页表
    ; 使用二级页表方式：一个页目录有1024个页目录项。
    ; 一个页目录项（页表）有1024个页表项，一个页表项管理4KB空间，总共1024*1024*4KB=4GB
    ; 我们将页目录数据放在从 PAGE_DIR_TABLE_POS 开始的 1024*4B=4096B(4KB) 中
    ; 页表数据放在从 PAGE_DIR_TABLE_POS + 4096B 后的 1024*4B=4096B(4KB) 中
    ; 1024个页目录项与 1024个页表共计 8KB
    setup_page:
        ; 初始化页目录项(1024个，每个4B = 4096B)
        ; 进行逐字节清0
        mov ecx,4096
        mov esi,0
        .clear_page_dir:
            mov byte [PAGE_DIR_TABLE_POS + esi],0
            inc esi
            loop .clear_page_dir    ; 循环ecx=4096次
        
        ;创建页目录项(Page Directory Entry-PDE)
        .create_pde:
            mov eax,PAGE_DIR_TABLE_POS  ; 表示PDE放在出了低端1MB空间的第一个字节
            add eax,0x1000              ; eax表示第一个 页表 的位置兼
                                        ;   第一个 页表项 属性
            ; eax = PAGE_DIR_TABLE_POS + 0x1000原因：
            ;   1024个将要初始化的页目录占用了前(0x1000 = 4096B 的内存） 

            mov ebx,eax                 ; 为.create_pte做准备,ebx为基址

            ; 将页目录项 0 与 0xc00都存储为第一个页表的地址,每个页表 表示4MB内存，
            ; 这样0xc03f_ffff以下的地址和 0x003f_ffff以下的地址都指向相同的页表 
            ; 这是为将地址映射为内核地址做准备

            or eax,PG_US_U | PG_RW_W | PG_P
            ; 该 页目录项 属性:用户级别 | 可读可写 | 页表存在
            ; 此时eax的值符合一个页目录项的要求了：
            ;   高20位指向页表的4k整数倍地址，低12位为相关属性

            ; 初始化0与768号页目录表
            mov [PAGE_DIR_TABLE_POS + 0x0],eax
            mov [PAGE_DIR_TABLE_POS + 0xc00],eax ; mov [PAGE_DIR_TABLE_POS + 768*4],eax
            ; 0xc00表示第769个(768号)表占用的页目录项的号(0xc00/4B=768[占用了768个所以是第769个]),
            ; 768号及以上的 目录项 (768~1023号) 用于内核空间
            ; 即页表指向的0xc0000_0000 ~ 0xffff_ffff共计1G属于内核
            ; 0x0 ~ 0xbfff_ffff 共计3G属于用户进程与 loader(进入内核后可以不再占用)

            ; 虚拟地址 3G~4G是内核占用，而物理地址0~4M放了所有的操作系统代码
            ; 第一个 页目录项 管理的0~4MB与物理内存一一对应保证loader正常运行
            
            sub eax,0x1000
            mov [PAGE_DIR_TABLE_POS + 4092] , eax ;eax此时为PAGE_DIR_TABLE_POS
            ; 让最后一个(1023号） 页目录项 指向目录表自己的地址
            ; 属性PG_US_U是为了给init进程(运行在用户空间)访问这个页目录项
        
        ;创建(第一个页表的)页表项(Page Table Entry-PTE)
        mov ecx,256         ; 初始化第一张页表(0~4MB)的前256个页表项(1MB)
                            ; 原因：我们的操作系统 代码 只使用内存最低端1MB
                            ; 内核会处理缺页中断所以不用担心
        mov esi, 0
        mov edx,PG_US_U | PG_RW_W | PG_P ; 高20位为空表示管理0~4KB
        .create_pte:
            mov [ebx+esi*4],edx         ; 每个页表项4字节
            ; 此时ebx已经通过上面eax赋值为0x101000,也就是第一个页表的地址
            add edx,4096 ; 一个页表项管理4KB=4096B
            inc esi
            loop .create_pte
        
        ; 创建内核的PDE(第769[768号]个~第1023[1022号]个页目录项)
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x2000              ; 此时eax为第二个页表的位置
        or eax, PG_US_U | PG_RW_W | PG_P
        mov ebx, PAGE_DIR_TABLE_POS
        mov ecx, 254                 ; 范围为769~1022号目录项(1022-769+1=254)
                                    ;  第1024个(1023号)目录已经在上文设置
                                    ; 此时初始化的是管理内核空间的页目录项
        mov esi,769
        .create_kernel_pde:
            mov [ebx+esi*4],eax
            inc esi
            add eax,0x1000
            loop .create_kernel_pde
        
        ret
    
    ; 在32位模式下读取硬盘n个扇区
    ; eax=LBA扇区号
    ; ebx=将数据写入的内存地址
    ; ecx=读入的扇区数
    rd_disk_m_32:
        ; 数据预处理
        mov esi,eax     ; 备份eax,源变址寄存器
        mov di,cx       ; 备份cx,读取扇区数

        ; 第一步：设置要读写的扇区数量
        .step_1:
            mov dx,0x1f2    ; 调用端口号，写操作为设置Primary通道的读取扇区数量
            mov al,cl       ; 设置读取位数
            out dx,al       ; 写操作为设置Primary通道的读取扇区数量

            mov eax,esi     ; 恢复ax

        ; 第二步：将LBA地址存入 0x1f3 ~ 0x1f6 端口
        .step_2:
            ; LBA地址7~0位存入0x1f3端口
            mov dx,0x1f3
            out dx,al

            ; LBA地址15~8位写入0x1f4端口
            mov cl,8        ; eax右移位数
            
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
                mov [ebx],ax
                add ebx,2            ; 将ax放入[ebx],并移动ebx指针位置
                loop .go_on_read    ; cx为循环计数器

        ret

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

        ;加载kernel
        mov eax,KERNEL_START_SECTOR     ; kernel.bin所在扇区号
        mov ebx,KERNEL_BIN_BASE_ADDR    ; kernel.bin写入内存的位置
        mov ecx,KERNEL_SECTOR_SIZE      ; kernel占用扇区数

        call rd_disk_m_32


        ;创建页目录及页表并初始化内存位图
        call setup_page

        ;将描述符地址以及偏移量写入内存gdt_ptr,一会儿用新地址重新加载
        sgdt [gdt_ptr]              ; 倒出并储存到原来gdt所有的位置
        ; 处理gdtr原因：进入内核之后虚拟地址0~4MB需要让出来给用户进程
        ;   如果不将gdtr基址抬高3GB则0~4MB虚拟地址还是需要与
        ;   0~4MB物理地址建立一一对应的关系，这是我们不想要的.


        ; gdt_ptr处的值有两部分：前部分2字节大小的GDT界限(GDT_LIMIT)，
        ; 其后为4字节大小的基址(GDT_BASE)
        mov ebx, [gdt_ptr+2]    ; 此时ebx为GDT_BASE
        add dword [ebx + 0x18 + 4],0xc000_0000 
        ; 显存段描述符为第三个描述符，一个描述符大小8B，故ebx要加上0x18=24B
        ;  才能访问显存段描述符。段描述符记录段基址最高位部分是在段描述符的
        ;  高4字节的最高1字节,故还要加上4B

        ;将 gdt视频描述符中的段基址+0xc000_0000使其成为内核所在的高地址
        ; 此时显存gdt通过访问升高3GB之后的虚拟地址实际上还是在访问原来同样的物理地址
        add dword [gdt_ptr+2],0xc000_0000

        add esp,0xc000_0000         ; 栈指针同样映射到内核地址

        ; 把页目录地址赋给cr3
        mov eax,PAGE_DIR_TABLE_POS
        mov cr3,eax

        ; 打开cr0位段pg位（第31位）
        mov eax,cr0
        or eax,0x8000_0000  ; 1b<<31
        mov cr0,eax

        ; 开启分页后，用gdt新地址重新加载
        lgdt [gdt_ptr]      ;重新加载

        ; 刷新流水线
        jmp SELECTOR_CODE:enter_kernel

    ; 将kernel.bin中的segment拷贝到编译的地址
    kernel_init:
        xor eax,eax
        xor ebx,ebx     ; 记录程序头表地址
        xor ecx,ecx     ; cx记录程序头表中program header数量
        xor edx,edx     ; dx记录program header尺寸，即e_phentsize

        ; 处理 elf header
        mov dx,[KERNEL_BIN_BASE_ADDR+42]    ; 偏移42字节处的属性是e_phentsize,
                        ;  表示program header table中每个program header大小
        mov ebx,[KERNEL_BIN_BASE_ADDR+28]   ; 表示e_phoff，程序头表 相对偏移量位置
                ; 也表示第一个 程序头(program header)在文件中的偏移量
        add ebx,KERNEL_BIN_BASE_ADDR        ; ebx为程序头表的实际地址
        
        mov cx,[KERNEL_BIN_BASE_ADDR+44]    ; e_phnum,program header数

        .each_segment:
            cmp byte [ebx+0], PT_NULL
            ; 等于PT_NULL表示这个program header未使用
            je .PTNULL

            ; 为函数memcpy压入参数，参数从右往左依次压入
            ; 函数原型类似于memcpy(dst,src,size)
            ; 第三个参数:size
            push dword [ebx+16]; 此处为program header的p_filesz

            ; 第二个参数:src
            mov eax, [ebx+4]; p_offset:段在文件中起始偏移字节
            add eax,KERNEL_BIN_BASE_ADDR; 此时eax为该段物理地址
            push eax

            ;第一个参数：目标地址
            push dword [ebx+8]; p_vaddr:本段在内存中的起始虚拟地址

            call mem_cpy        ;调用mem_cpy完成段复制
            add esp,12          ; 清理栈中压入的三个参数(栈从高位往低位扩展)

        .PTNULL:
            add ebx,edx     ; edx为program header大小，即e_phentsize
                            ; 此时ebx指向下一个program header
            loop .each_segment

        ret


    ; 逐字节拷贝 mem_cpy(dst,src,size)
    ; 输入:dst目标地址, src复制起始地址, size复制的字节数
    ; 输出:无
    mem_cpy:
        cld     ; 清除方向位,后面movsb用到

        push ebp ; 后面要更新栈底，入栈备份
        mov ebp, esp    ; 将ebp放到栈顶，此时可以通过偏移量访问参数
        push ecx        ; rep指令用到了ecx，备份

        mov edi,[ebp+8]     ; dst
        mov esi,[ebp+12]    ; src
        mov ecx,[ebp+16]    ; size

        ; 正常运转依赖于strip删除节
        ; size=0直接不拷贝
        cmp ecx,0
        je .copy_end

        ; 手写逐字节清零
        ; xor eax,eax
        ; .copy_byte:
        ;     mov al ,[esi]
        ;     mov [edi],al
        ;     inc esi
        ;     inc edi
        ;     loop .copy_byte

        rep movsb           ; 逐字节拷贝
        ; movsb：搬运1字节，从DS:SI 搬到ES:DI
        ; 指针递增由CPU自动完成(方向看方向位，在前面已经清零，为往后扩展）
        ; DS,ES在进入保护模式之初已经被赋值为同样选择子，指向同一个段描述符

        .copy_end:
        ; 恢复备份
        pop ecx
        pop ebp

        ret

    enter_kernel:
        mov byte [gs:160],'V'
        ;   视频段段地址已经被更新，用字符v表示virtual addr
        call kernel_init
        mov esp,0xc009f000          ; 0x9f000对齐4KB为以后pcb(程序控制块)做准备

        mov byte [gs:160],'T'       ; for test
        xchg bx,bx                  ; 断点测试
        jmp KERNEL_ENTRY_POINT