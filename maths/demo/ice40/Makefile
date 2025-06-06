## Project F: Maths Demo - iCEBreaker Makefile
## (C)2021 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC  = ${PATH_LIB}/clock/ice40/clock_gen_480p.sv
ADD_SRC += ${PATH_LIB}/display/display_480p.sv
ADD_SRC += ../func_circle.sv ../func_cubed.sv 
ADD_SRC += ../func_polynomial.sv ../func_squared.sv

top_graphing: top_graphing.rpt top_graphing.bin

%.json: %.sv $(ADD_SRC)
	yosys -ql $(subst .json,,$@)-yosys.log -p 'synth_ice40 -dsp -abc2 -top $(subst .json,,$@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $@

clean:
	rm -f top*.json top*.asc top*.rpt top*.bin top*yosys.log

all: top_graphing

.PHONY: all clean
