## Project F: Mandelbrot Set - Verilator Sim Makefile
## (C)2023 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/mandelbrot-set-verilog/

VFLAGS = -O3 --x-assign fast --x-initial fast --noassert
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Verilog Library
PROJF_LIBS += -I../../../lib/clock
PROJF_LIBS += -I../../../lib/display
PROJF_LIBS += -I../../../lib/essential
PROJF_LIBS += -I../../../lib/graphics
PROJF_LIBS += -I../../../lib/maths
PROJF_LIBS += -I../../../lib/memory

mandel: mandel.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator ${VFLAGS} -I.. ${PROJF_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: mandel

clean:
	rm -rf ./obj_dir

.PHONY: all clean
