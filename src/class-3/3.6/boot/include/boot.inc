; 配置文件
LOADER_BASE_ADDR equ 0x900   ; loader在内存中的位置，由mbr放入
LOADER_START_SECTOR equ 0x2     ; loader在硬盘上的逻辑扇区地址，即LBA地址，
                                ; 放在第二块（从0开始）扇区