## top_kill_the_bit - iCESugar Makefile

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
ADD_SRC += ${PATH_LIB}/tm1638/tm1638.sv
ADD_SRC += ${PATH_LIB}/tm1638/tm1638_led_key.sv
ADD_SRC += ${PATH_LIB}/essential/sb_inout.sv
ADD_SRC += ../kill_the_bit.sv


kill_the_bit: kill_the_bit.rpt kill_the_bit.bin kill_the_bit.link

%.json: top_%.sv $(ADD_SRC)
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

all: kill_the_bit

kill_the_bit.sim: top_kill_the_bit_tb.vcd

%.vcd: %.sv $(ADD_SRC)

	#-- Compile
	iverilog -g2012 -Wall -DSIMULATION -I.. $< $(ADD_SRC) -o $(basename $@).out
	
	#-- Simulate
	./$(basename $@).out

	#-- Visualize the simulation with gtkwave
	killall gtkwave || true
	gtkwave $@ $(basename $@).gtkw &


clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean kill_the_bit.sim
