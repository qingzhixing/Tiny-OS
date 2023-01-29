; 配置文件
LOADER_BASE_ADDR equ 0x900   ; loader在内存中的位置，由mbr放入
LOADER_START_SECTOR equ 0x2     ; loader在硬盘上的逻辑扇区地址，即LBA地址，
                                ; 放在第二块（从0开始）扇区

; gdt描述符属性
DESC_G_4K   equ	  1_000_0000_0000_0000_0000_0000b   ;  描述符G位粒度，为4KB
DESC_D_32   equ	   1_00_0000_0000_0000_0000_0000b   ;  操作数为32位
DESC_L	    equ	    0_0_0000_0000_0000_0000_0000b   ;  64位代码标记，0为使用32位代码段，目前属于保留位
DESC_AVL    equ	     _0_0000_0000_0000_0000_0000b	;  此位无意义，留给操作系统用的，暂置为0  

DESC_LIMIT_CODE2  equ 1111_0000_0000_0000_0000b     ; 代码段段界限的第二部分(第一部分在低32位部分的前16位即前2字节)
                                                    ; 与第一部分将组成20个二进制1即0xFFFF
DESC_LIMIT_DATA2  equ DESC_LIMIT_CODE2              ; 同 DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2  equ 0000_000000000000000b

DESC_P	    equ		  1_000000000000000b            ; 段存在标记，供cpu检查，1则为存在
DESC_DPL_0  equ		   00_0000000000000b            ; 特权级为0,最高特权级
DESC_DPL_1  equ		   01_0000000000000b            ; 特权级1
DESC_DPL_2  equ		   10_0000000000000b            ; 特权级2
DESC_DPL_3  equ		   11_0000000000000b            ; 特权级3
DESC_S_CODE equ		     1_000000000000b            ; S位为1表示为普通内存段,非系统段
DESC_S_DATA equ	  DESC_S_CODE                       ; 普通数据段，非系统段
DESC_S_sys  equ		     0_000000000000b            ; 系统段S位

DESC_TYPE_CODE  equ	      1000_00000000b	;x=1,c=0,r=0,a=0 代码段是
                                            ; 可执行的,非依从的,不可读的,已访问位a清0.  
DESC_TYPE_DATA  equ	      0010_00000000b	;x=0,e=0,w=1,a=0 数据段是
                                            ; 不可执行的,向上扩展的,可写的,已访问位a清0.

; 代码段gdt高32位即高4字节
DESC_CODE_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
; 0x00<<24 : 31~24位为段基址第三部分为0. 其次是G位, D/B, L, AVL, 段界限2, P, DPL, S, TYPE, 段基址第二部分为0
DESC_DATA_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

; 选择子属性
; 请求特权级:0,1,2,3
RPL0  equ   00b
RPL1  equ   01b
RPL2  equ   10b
RPL3  equ   11b
TI_GDT	 equ   000b
TI_LDT	 equ   100b