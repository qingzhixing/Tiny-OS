BUILD=./build
SRC=.
BOOT_SRC_PATH=$(SRC)/boot
BOOT_BUILD_PATH=$(BUILD)/boot
KERNEL_SRC_PATH=$(SRC)/kernel
KERNEL_BUILD_PATH=$(BUILD)/kernel

# 处理.S to .bin
$(BOOT_BUILD_PATH)/%.bin:$(BOOT_SRC_PATH)/%.S
	$(shell mkdir -p $(BOOT_BUILD_PATH))
	nasm -I $(BOOT_SRC_PATH) -f bin $< -o $@

# 处理.c to .o
$(KERNEL_BUILD_PATH)/%.o:$(KERNEL_SRC_PATH)/%.c
	$(shell mkdir -p $(KERNEL_BUILD_PATH))
	gcc $< -m32 -c -o $@

# 处理 kernel:.o to .bin
# 0xc0001500为内核入口虚拟地址:物理地址0x1500
# 0x1500必定为loader.bin之后的内存，经过elf解析初始化之后的代码放在那儿
$(KERNEL_BUILD_PATH)/%.bin:$(KERNEL_BUILD_PATH)/%.o
	$(shell mkdir -p $(KERNEL_BUILD_PATH))
	ld $< -N -m elf_i386 -Ttext 0xc0001500 -e main -o $@

$(BUILD)/master.img:$(BOOT_BUILD_PATH)/mbr.bin\
					$(BOOT_BUILD_PATH)/loader.bin\
					$(KERNEL_BUILD_PATH)/main.bin
	$(shell mkdir -p $(BUILD))
	yes | bximage -q -mode=create -hd=16M -sectsize=512 -imgmode=flat $@
	dd if=$(BOOT_BUILD_PATH)/mbr.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BOOT_BUILD_PATH)/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc
	dd if=$(KERNEL_BUILD_PATH)/main.bin of=$@ bs=512 count=200 seek=9 conv=notrunc

.PHONY: clean
clean:
	rm -rf build/

.PHONY:bochs
bochs:$(BUILD)/master.img
	bochs -q -f bochsrc.disk

test:$(KERNEL_BUILD_PATH)/main.bin