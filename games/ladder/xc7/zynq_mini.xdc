set_property IOSTANDARD LVCMOS33 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports IR]
set_property IOSTANDARD LVCMOS33 [get_ports LED1]
set_property IOSTANDARD LVCMOS33 [get_ports LED2]
set_property IOSTANDARD LVCMOS33 [get_ports LED3]
set_property IOSTANDARD LVCMOS33 [get_ports LED4]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports SCL]
set_property IOSTANDARD LVCMOS33 [get_ports SDA]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property PACKAGE_PIN K17 [get_ports CLK]
set_property PACKAGE_PIN W20 [get_ports IR]
set_property PACKAGE_PIN M19 [get_ports rst_n]
set_property PACKAGE_PIN N18 [get_ports {LED[3]}]
set_property PACKAGE_PIN N20 [get_ports {LED[5]}]
set_property PACKAGE_PIN P19 [get_ports {LED[4]}]
set_property PACKAGE_PIN P20 [get_ports {LED[6]}]
set_property PACKAGE_PIN T16 [get_ports LED2]
set_property PACKAGE_PIN T20 [get_ports {LED[7]}]
set_property PACKAGE_PIN U14 [get_ports SDA]
set_property PACKAGE_PIN U15 [get_ports {LED[0]}]
set_property PACKAGE_PIN U17 [get_ports LED3]
set_property PACKAGE_PIN U18 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property PACKAGE_PIN V15 [get_ports LED4]
set_property PACKAGE_PIN W15 [get_ports SCL]
set_property PACKAGE_PIN Y14 [get_ports LED1]

create_clock -period 20.000 -name CLK -waveform {0.000 10.000} [get_ports CLK]
