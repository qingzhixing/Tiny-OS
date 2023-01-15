BUILD=./build
SRC=.
INCLUDE_PATH=$(SRC)/boot/include

$(BUILD)/%.bin:$(INCLUDE_PATH)/%.S
	$(shell mkdir -p $(BUILD))
	nasm -I $(INCLUDE_PATH) -f bin $< -o $@

$(BUILD)/master.img:$(BUILD)/mbr.bin
	$(shell mkdir -p $(BUILD))
	yes | bximage -q -mode=create -hd=16M -sectsize=512 -imgmode=flat $@
	dd if=$< of=$@ bs=512 count=1 conv=notrunc

.PHONY: clean
clean:
	rm -rf build/

.PHONY:bochs
bochs:$(BUILD)/master.img
	bochs -q -f bochsrc.disk

test:$(BUILD)/mbr.bin