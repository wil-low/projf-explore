## Project F: 2D Shapes - Verilator Sim Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/fpga-shapes/

# render module version
RENDER_MODS = '320x180'

CFLAGS = -O2
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Verilog Library
PROJF_LIBS += -I../../../lib/clock
PROJF_LIBS += -I../../../lib/display
PROJF_LIBS += -I../../../lib/graphics
PROJF_LIBS += -I../../../lib/memory

demo: demo.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator -I.. -I../${RENDER_MODS} ${PROJF_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${CFLAGS} ${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: demo

clean:
	rm -rf ./obj_dir

.PHONY: all clean
