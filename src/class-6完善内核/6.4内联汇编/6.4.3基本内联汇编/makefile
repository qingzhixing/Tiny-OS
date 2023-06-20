GCCFLAG= -Wall -W -no-pie
.PHONY: clean
clean:
	rm -f *.o

%.o:%.c
	gcc $(GCCFLAG) $< -o $@
	chmod u+x $@
	@echo "compile complete Successfully!"
	./$@