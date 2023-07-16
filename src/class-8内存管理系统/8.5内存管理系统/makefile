BUILD=./build
SRC=.

# 生成器配置
CLIB = -I lib/kernel/ -I lib/ -I kernel/ -I device/
GCCFLAGS = -Wall -m32 -fno-stack-protector $(CLIB) -c -fno-builtin -W -Wstrict-prototypes -Wmissing-prototypes
ENTRY_POINT = 0xc0001500
LDFLAGS = -N -m elf_i386 -Ttext $(ENTRY_POINT) -e main

# 处理 boot/
BOOT_SRC_PATH=$(SRC)/boot
BOOT_BUILD_PATH=$(BUILD)/boot

$(BOOT_BUILD_PATH)/%.bin:$(BOOT_SRC_PATH)/%.S
	$(shell mkdir -p $(BOOT_BUILD_PATH))
	nasm -I $(BOOT_SRC_PATH) -f bin $< -o $@


# 处理 kernel/
KERNEL_SRC_PATH=$(SRC)/kernel
KERNEL_BUILD_PATH = $(BUILD)/kernel
KERNEL_C_BUILD_PATH=$(KERNEL_BUILD_PATH)/c
KERNEL_ASM_BUILD_PATH=$(KERNEL_BUILD_PATH)/asm

$(KERNEL_ASM_BUILD_PATH)/%.o:$(KERNEL_SRC_PATH)/%.S
	$(shell mkdir -p $(KERNEL_ASM_BUILD_PATH))
	nasm -I $(KERNEL_SRC_PATH) -f elf $< -o $@

$(KERNEL_C_BUILD_PATH)/%.o:$(KERNEL_SRC_PATH)/%.c
	$(shell mkdir -p $(KERNEL_C_BUILD_PATH))
	gcc $(GCCFLAGS) $< -c -o $@


# 处理 device/
DEVICE_SRC_PATH=$(SRC)/device
DEVICE_BUILD_PATH=$(BUILD)/device

$(DEVICE_BUILD_PATH)/%.o:$(DEVICE_SRC_PATH)/%.c
	$(shell mkdir -p $(DEVICE_BUILD_PATH))
	gcc $(GCCFLAGS) $< -c -o $@

# 处理 lib/
LIB_SRC_PATH=$(SRC)/lib
LIB_BUILD_PATH=$(BUILD)/lib

$(LIB_BUILD_PATH)/%.o:$(LIB_SRC_PATH)/%.c
	$(shell mkdir -p $(LIB_BUILD_PATH))
	gcc $(GCCFLAGS) $< -c -o $@

# 处理 lib/kernel/
LIB_KERNEL_SRC_PATH=$(SRC)/lib/kernel
LIB_KERNEL_BUILD_PATH=$(BUILD)/lib/kernel
LIB_KERNEL_ASM_BUILD_PATH=$(LIB_KERNEL_BUILD_PATH)/asm
LIB_KERNEL_C_BUILD_PATH=$(LIB_KERNEL_BUILD_PATH)/c

$(LIB_KERNEL_ASM_BUILD_PATH)/%.o:$(LIB_KERNEL_SRC_PATH)/%.S
	$(shell mkdir -p $(LIB_KERNEL_ASM_BUILD_PATH))
	nasm -I $(LIB_KERNEL_SRC_PATH) -f elf $< -o $@

$(LIB_KERNEL_C_BUILD_PATH)/%.o:$(LIB_KERNEL_SRC_PATH)/%.c
	$(shell mkdir -p $(LIB_KERNEL_C_BUILD_PATH))
	gcc $(GCCFLAGS) $< -c -o $@


objfiles = $(KERNEL_C_BUILD_PATH)/main.o\
			$(KERNEL_C_BUILD_PATH)/init.o\
			$(KERNEL_C_BUILD_PATH)/interrupt.o\
			$(KERNEL_C_BUILD_PATH)/debug.o\
			$(LIB_KERNEL_C_BUILD_PATH)/bitmap.o\
			$(LIB_KERNEL_ASM_BUILD_PATH)/print.o\
			$(KERNEL_ASM_BUILD_PATH)/kernel.o\
			$(LIB_BUILD_PATH)/string.o\
			$(DEVICE_BUILD_PATH)/timer.o

# 处理 kernel.bin
# main.o必须在前面，要遵守“调用在前，实现在后”的顺序
# 否则会出现链接之后生成的虚拟地址不准确的问题
$(KERNEL_BUILD_PATH)/kernel.bin:$(objfiles)
	$(shell mkdir -p $(KERNEL_BUILD_PATH))
	ld $(LDFLAGS) $^ -o $@
	strip --remove-section=.note.gnu.property $@

$(BUILD)/master.img:$(BOOT_BUILD_PATH)/mbr.bin\
					$(BOOT_BUILD_PATH)/loader.bin\
					$(KERNEL_BUILD_PATH)/kernel.bin
	$(shell mkdir -p $(BUILD))
	yes | bximage -q -mode=create -hd=16M -sectsize=512 -imgmode=flat $@
	dd if=$(BOOT_BUILD_PATH)/mbr.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BOOT_BUILD_PATH)/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc
	dd if=$(KERNEL_BUILD_PATH)/kernel.bin of=$@ bs=512 count=200 seek=9 conv=notrunc

.PHONY: clean
clean:
	rm -rf build/

.PHONY:build
build:$(BUILD)/master.img

.PHONY:bochs
bochs:build
	bochs -q -f bochsrc.disk

test:$(LIB_KERNEL_ASM_BUILD_PATH)/print.o