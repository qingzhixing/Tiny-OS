build: syscall_write.S
	nasm -f elfx32 -o syscall_write.o syscall_write.S -g -F dwarf
	ld -m elf32_x86_64 -o syscall_write.bin syscall_write.o

run: build
	chmod u+x syscall_write.bin
	./syscall_write.bin

PHONY: clean
clean:
	rm -f *.o
	rm -f *.bin