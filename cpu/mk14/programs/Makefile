all: \
	test.mem \
	test2.mem \
	multiply.mem \
	collatz.mem \
	display.mem \
	clock.mem \
	segtris.mem \
	ambush.mem \
	SCIOS_Version_2.mem

%.mem: %.asm
	~/program/sbasm3/sbasm $<
	perl lst2mem.pl $(basename $@).lst

clean:
	rm -f *.lst *.mem

.PHONY: all
