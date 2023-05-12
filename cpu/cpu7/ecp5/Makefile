TARGET=cpu7

# included modules
PATH_LIB = ../../../lib
ADD_SRC += top_$(TARGET).sv
ADD_SRC += ${PATH_LIB}/memory/bram_read_async.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv
ADD_SRC += ${PATH_LIB}/container/stack.sv
ADD_SRC += ${PATH_LIB}/3rd_party/zipcpu/rtl/core/slowmpy.v
ADD_SRC += ${PATH_LIB}/maths/divu_int.sv
ADD_SRC += ../core.sv
ADD_SRC += ../cpu7_soc.sv

TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

$(TARGET).json: top_$(TARGET).sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p "synth_ecp5 -top top_$(basename $@) -json $@" $(ADD_SRC)

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --45k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf colorlight_i9.lpf --freq 65

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf ${TARGET}.svf --compress $< $@

${TARGET}.svf : ${TARGET}.bit

prog: ${TARGET}.bit
	ecpdap program --freq 5000 ${TARGET}.bit

flash: ${TARGET}.bit
	ecpdap flash write --freq 5000 ${TARGET}.bit

clean:
	rm -f *.svf *.bit *.config *.ys

.PHONY: prog flash clean
