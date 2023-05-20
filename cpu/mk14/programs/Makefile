all: test.mem test2.mem SCIOS_Version_2.mem multiply.mem collatz.mem display.mem clock.mem segtris.mem

%.mem: %.asm
	~/program/sbasm3/sbasm $<
	perl lst2mem.pl $(basename $@).lst

clean:
	rm -f *.lst *.mem

.PHONY: all
