GCCFLAG= -Wall -W -no-pie -g
.PHONY: clean
clean:
	rm -f *.o

%.o:%.c
	gcc $(GCCFLAG) $< -m32 -o $@
	chmod u+x $@
	@echo "compile complete Successfully!"
	./$@