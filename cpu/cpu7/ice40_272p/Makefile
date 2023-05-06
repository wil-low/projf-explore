## cpu7 - iCESugar Makefile

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
ADD_SRC += ${PATH_LIB}/memory/bram_read_async.sv
ADD_SRC += ${PATH_LIB}/container/stack.sv
ADD_SRC += ${PATH_LIB}/3rd_party/zipcpu/rtl/core/slowmpy.v
ADD_SRC += ${PATH_LIB}/maths/divu_int.sv
ADD_SRC += ../core.sv
ADD_SRC += ../cpu7_soc.sv

cpu7: cpu7.rpt cpu7.bin cpu7.link

%.json: top_%.sv $(ADD_SRC) generate_mem
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -dsp -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

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

all: cpu7

cpu7.sim: top_cpu7_tb.vcd

%.vcd: %.sv $(ADD_SRC) generate_mem

	#-- Compile
	iverilog -g2012 -Wall -DSIMULATION -I.. $< $(ADD_SRC) -o $(basename $@).out
	
	#-- Simulate
	./$(basename $@).out

	#-- Visualize the simulation with gtkwave
	killall gtkwave || true
	gtkwave $@ $(basename $@).gtkw &

generate_mem: ../test.mem

../test.mem: ../programs/test.torth ../constants.svh
	perl ../emulation/cpu7_compile.pl ../programs/test.torth ../constants.svh > ../test.mem

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log *.out *.vcd

.PHONY: all clean cpu7.sim generate_mem
