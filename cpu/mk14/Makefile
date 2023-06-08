mem:
	cd programs && make && cd ..

sim: mem
	cd ice40_272p && touch top_mk14_tb.sv && make mk14.sim && cd ..

link: mem
	cd ice40_272p && make mk14.link && cd ..

prog: mem
	cd ecp5 && make prog && cd ..

flash: mem
	cd ecp5 && make flash && cd ..

gowin_prog: mem
	cd gowin && openFPGALoader -b tangnano9k mk14/impl/pnr/mk14.fs

gowin_flash: mem
	cd gowin && openFPGALoader -b tangnano9k -f mk14/impl/pnr/mk14.fs


# ./upload_ram_gowin.sh programs/clock.hex 
