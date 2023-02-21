## Project F: Hardware Sprites - iCESugar Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/hardware-sprites/

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icesugar.pcf

# iCELink connection
ICELINK_DEV = /dev/$(shell lsblk -f | grep iCELink |  cut -d ' ' -f 1)
ICELINK_DIR = /tmp/iCELink

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ice40/clock_272p.sv
ADD_SRC += ${PATH_LIB}/display/clut_simple.sv
ADD_SRC += ${PATH_LIB}/display/display_272p.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ../sprite_inline.sv
ADD_SRC += ../sprite_rom.sv
ADD_SRC += ../sprite.sv

tinyf_inline: tinyf_inline.rpt tinyf_inline.bin tinyf_inline.link
tinyf_rom: tinyf_rom.rpt tinyf_rom.bin tinyf_rom.link
tinyf_scale: tinyf_scale.rpt tinyf_scale.bin tinyf_scale.link
tinyf_move: tinyf_move.rpt tinyf_move.bin tinyf_move.link
hourglass: hourglass.rpt hourglass.bin hourglass.link
hedgehog: hedgehog.rpt hedgehog.bin hedgehog.link

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

all: tinyf_inline tinyf_rom tinyf_scale hourglass hedgehog

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean
