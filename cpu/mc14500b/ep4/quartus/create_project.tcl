# Copyright (C) 2022  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and any partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details, at
# https://fpgasoftware.intel.com/eula.

# Quartus Prime: Generate Tcl File for Project
# File: create_project.tcl
# Generated on: Thu Apr  6 17:48:17 2023

# Load Quartus Prime Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "mc14500b_demo"]} {
		puts "Project mc14500b_demo is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists mc14500b_demo]} {
		project_open -revision top mc14500b_demo
	} else {
		project_new -revision top mc14500b_demo
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY "Cyclone IV E"
	set_global_assignment -name DEVICE EP4CE6F17C8
	set_global_assignment -name TOP_LEVEL_ENTITY top_mc14500b_demo
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 22.1STD.0
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "12:03:04  лютого 20, 2023"
	set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.0 Lite Edition"
	set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
	set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
	set_global_assignment -name NOMINAL_CORE_SUPPLY_VOLTAGE 1.2V
	set_global_assignment -name EDA_SIMULATION_TOOL "Questa Intel FPGA (Verilog)"
	set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
	set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "VERILOG HDL" -section_id eda_simulation
	set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_timing
	set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_symbol
	set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_signal_integrity
	set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_boundary_scan
	set_global_assignment -name ENABLE_OCT_DONE OFF
	set_global_assignment -name ENABLE_CONFIGURATION_PINS OFF
	set_global_assignment -name ENABLE_BOOT_SEL_PIN OFF
	set_global_assignment -name USE_CONFIGURATION_DEVICE OFF
	set_global_assignment -name CRC_ERROR_OPEN_DRAIN OFF
	set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED"
	set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"
	set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -rise
	set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -fall
	set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -rise
	set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -fall
	set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
	set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
	set_global_assignment -name SYSTEMVERILOG_FILE ../../mc14500b.sv
	set_global_assignment -name SYSTEMVERILOG_FILE ../top_mc14500b_demo.sv
	set_global_assignment -name SYSTEMVERILOG_FILE ../../mc14500b_demo.sv
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name SEARCH_PATH ../../../../lib/memory
	set_global_assignment -name SEARCH_PATH ../../../../lib/essential
	set_global_assignment -name SEARCH_PATH ../../ice40_272p
	set_location_assignment PIN_F9 -to LED2
	set_location_assignment PIN_E10 -to LED1
	set_location_assignment PIN_C9 -to LED3
	set_location_assignment PIN_D9 -to LED4
	set_location_assignment PIN_E1 -to CLK
	set_location_assignment PIN_C6 -to LED[0]
	set_location_assignment PIN_F8 -to LED[1]
	set_location_assignment PIN_D8 -to LED[2]
	set_location_assignment PIN_E9 -to LED[3]
	set_location_assignment PIN_B12 -to LED[4]
	set_location_assignment PIN_B13 -to LED[5]
	set_location_assignment PIN_D5 -to LED[6]
	set_location_assignment PIN_B11 -to LED[7]
	set_location_assignment PIN_N13 -to RST
	set_location_assignment PIN_M15 -to BTN1
	set_location_assignment PIN_M16 -to BTN2
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}
