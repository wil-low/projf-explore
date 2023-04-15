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
ADD_SRC += ${PATH_LIB}/memory/ice40/bram_sdp.sv
ADD_SRC += ../core.sv
ADD_SRC += ../cpu7_soc.sv

cpu7: cpu7.rpt cpu7.bin cpu7.link

%.json: top_%.sv $(ADD_SRC) cmd.mem
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

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

%.vcd: %.sv $(ADD_SRC) cmd.mem

	#-- Compile
	iverilog -g2012 -Wall -I.. $< $(ADD_SRC) -o $(basename $@).out
	
	#-- Simulate
	./$(basename $@).out

	#-- Visualize the simulation with gtkwave
	killall gtkwave || true
	gtkwave $@ $(basename $@).gtkw &

generate_cmd: cmd.mem

cmd.mem: ../generate_cmd.sv
	iverilog -g2012 ../generate_cmd.sv -I.. -o generate_cmd.out
	#-- Simulate
	./generate_cmd.out

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log *.out *.vcd

.PHONY: all clean
