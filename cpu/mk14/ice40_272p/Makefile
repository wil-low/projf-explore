## mk14 - iCESugar Makefile

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# iCELink connection
ICELINK_DEV = /dev/$(shell lsblk -f | grep iCELink |  cut -d ' ' -f 1)
ICELINK_DIR = /tmp/iCELink

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/memory/bram_sqp.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638_led_key_memmap.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638_led_key.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638.sv
ADD_SRC += ${PATH_LIB}/essential/sb_inout.sv
ADD_SRC += ../core.sv
ADD_SRC += ../mk14_soc.sv

mk14: mk14.rpt mk14.bin mk14.link

%.json: top_%.sv $(ADD_SRC) generate_mem
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -dsp -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 -ql $(basename $@)-nextpnr.log --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $(subst top_,,$@)

%.link: %.bin
	# Send to iCELink
	mkdir -p $(ICELINK_DIR)
	sudo mount $(ICELINK_DEV) $(ICELINK_DIR)
	sudo cp $< $(ICELINK_DIR)
	sudo sync
	sudo umount $(ICELINK_DIR)

all: mk14

mk14.sim: top_mk14_tb.vcd generate_mem

%.vcd: %.sv $(ADD_SRC)

	#-- Compile
	iverilog -g2012 -Wall -DSIMULATION -I.. $< $(ADD_SRC) -o $(basename $@).out
	
	#-- Simulate
	./$(basename $@).out

	#-- Visualize the simulation with gtkwave
	killall gtkwave || true
	gtkwave $@ $(basename $@).gtkw &

generate_mem: ../programs/test.mem

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log *.out *.vcd

verilate: top_mk14.sv $(ADD_SRC)
	verilator --cc --build -I.. $< $(ADD_SRC)

.PRECIOUS: %.asc %.json

.PHONY: all clean mk14.sim generate_mem
