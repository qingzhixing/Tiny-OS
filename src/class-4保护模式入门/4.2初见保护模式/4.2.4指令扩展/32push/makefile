BUILD=./build
SRC=.
BOOT_PATH=$(SRC)/boot

$(BUILD)/%.bin:$(BOOT_PATH)/%.S
	$(shell mkdir -p $(BUILD))
	nasm -I $(BOOT_PATH) -f bin $< -o $@

$(BUILD)/master.img:$(BUILD)/mbr.bin\
					$(BUILD)/32push.bin
	$(shell mkdir -p $(BUILD))
	yes | bximage -q -mode=create -hd=16M -sectsize=512 -imgmode=flat $@
	dd if=$(BUILD)/mbr.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BUILD)/32push.bin of=$@ bs=512 count=1 seek=2 conv=notrunc

.PHONY: clean
clean:
	rm -rf build/

.PHONY:bochs
bochs:$(BUILD)/master.img
	bochs -q -f bochsrc.disk

test:$(BUILD)/32push.bin