## guess_number - iCESugar Makefile

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
ADD_SRC += ${PATH_LIB}/lc1602c/lc1602_i2c.sv
ADD_SRC += ${PATH_LIB}/random/lfsr.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ${PATH_LIB}/3rd_party/Tiny_But_Mighty_I2C_Master_Verilog/rtl/i2c_master.v
ADD_SRC += ../guess_number.sv


guess_number: guess_number.rpt guess_number.bin guess_number.link

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

all: guess_number

generate_cmd: cmd.mem

cmd.mem: ../generate_cmd.sv
	iverilog -g2012 ../generate_cmd.sv -I.. -o generate_cmd.out
	#-- Simulate
	./generate_cmd.out

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean
