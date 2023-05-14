all: test.mem SCIOS_Version_2.mem multiply.mem

%.lst: %.asm
	~/program/sbasm3/sbasm $<

%.mem: %.lst
	perl lst2mem.pl $<

clean:
	rm -f *.lst *.mem

.PHONY: all
