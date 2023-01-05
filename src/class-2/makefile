mbr.bin: mbr.S
	nasm -f bin -o mbr.bin mbr.S

master.img:mbr.bin
	yes | bximage -q -mode=create -hd=16M -sectsize=512 -imgmode=flat $@
	dd if=$< of=$@ bs=512 count=1 conv=notrunc

.PHONY: clean
clean:
	rm *.bin
	rm *.img
	rm *.lock

.PHONY:bochs
bochs:master.img
	bochs -q -f bochsrc.disk