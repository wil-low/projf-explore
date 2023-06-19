TARGET=mk14

# included modules
PATH_LIB = ../../../lib
ADD_SRC += top_$(TARGET).sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sqp.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638_led_key_memmap.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638_led_key.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638.sv
ADD_SRC += ${PATH_LIB}/essential/sb_inout.sv
ADD_SRC += ${PATH_LIB}/infrared/infrared_rx.sv
ADD_SRC += ${PATH_LIB}/uart-2/uart_rx.sv
ADD_SRC += ${PATH_LIB}/converter/intel_hex.sv
ADD_SRC += ${PATH_LIB}/display/display_272p.sv
ADD_SRC += ${PATH_LIB}/clock/ecp5/clock_272p.sv
ADD_SRC += ../core.sv
ADD_SRC += ../mmu.sv
ADD_SRC += ../ir_keypad.sv
ADD_SRC += ../mk14_soc.sv
ADD_SRC += ../vdu/vdu_vga_272p.sv
ADD_SRC += ../vdu/vdu.sv

TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

$(TARGET).json: top_$(TARGET).sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p "synth_ecp5 -top top_$(basename $@) -json $@" $(ADD_SRC)

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 -ql $(basename $@)-nextpnr.log --45k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf colorlight_i9.lpf --freq 25

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
