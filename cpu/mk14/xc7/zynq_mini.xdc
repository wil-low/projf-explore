set_property IOSTANDARD LVCMOS33 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports LED1]
set_property IOSTANDARD LVCMOS33 [get_ports LED2]
set_property IOSTANDARD LVCMOS33 [get_ports LED3]
set_property IOSTANDARD LVCMOS33 [get_ports LED4]
set_property PACKAGE_PIN T12 [get_ports LED1]
set_property PACKAGE_PIN U12 [get_ports LED2]
set_property PACKAGE_PIN V12 [get_ports LED3]
set_property PACKAGE_PIN W13 [get_ports LED4]
set_property PACKAGE_PIN K17 [get_ports CLK]

create_clock -period 20.000 -name CLK -waveform {0.000 10.000} [get_ports CLK]


set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN U18 [get_ports {LED[0]}]
set_property PACKAGE_PIN T17 [get_ports {LED[1]}]
set_property PACKAGE_PIN R17 [get_ports {LED[2]}]
set_property PACKAGE_PIN W20 [get_ports {LED[3]}]
set_property PACKAGE_PIN V20 [get_ports {LED[4]}]
set_property PACKAGE_PIN U20 [get_ports {LED[5]}]
set_property PACKAGE_PIN T20 [get_ports {LED[6]}]
set_property PACKAGE_PIN P20 [get_ports {LED[7]}]



