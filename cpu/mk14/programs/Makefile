all: test.mem SCIOS_Version_2.mem multiply.mem collatz.mem

%.mem: %.asm
	~/program/sbasm3/sbasm $<
	perl lst2mem.pl $(basename $@).lst

clean:
	rm -f *.lst *.mem

.PHONY: all
