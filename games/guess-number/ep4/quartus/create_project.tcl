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
# Generated on: Mon Feb 20 17:06:45 2023

# Load Quartus Prime Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "guess_number"]} {
		puts "Project guess_number is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists guess_number]} {
		project_open -revision top guess_number
	} else {
		project_new -revision top guess_number
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY "Cyclone IV E"
	set_global_assignment -name DEVICE EP4CE6F17C8
	set_global_assignment -name TOP_LEVEL_ENTITY top_guess_number
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 22.1STD.0
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "12:03:04  лютого 20, 2023"
	set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.0 Lite Edition"
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
	set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
	set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
	set_global_assignment -name SYSTEMVERILOG_FILE ../simple_score.sv
	set_global_assignment -name SDC_FILE top.sdc
	set_global_assignment -name SYSTEMVERILOG_FILE ../top_guess_number.sv
	set_location_assignment PIN_L6 -to vga_hsync
	set_location_assignment PIN_N3 -to vga_vsync
	set_location_assignment PIN_C3 -to vga_b[0]
	set_location_assignment PIN_D4 -to vga_b[1]
	set_location_assignment PIN_D3 -to vga_b[2]
	set_location_assignment PIN_E5 -to vga_b[3]
	set_location_assignment PIN_F6 -to vga_b[4]
	set_location_assignment PIN_F5 -to vga_g[0]
	set_location_assignment PIN_G5 -to vga_g[1]
	set_location_assignment PIN_F7 -to vga_g[2]
	set_location_assignment PIN_K8 -to vga_g[3]
	set_location_assignment PIN_L8 -to vga_g[4]
	set_location_assignment PIN_J6 -to vga_g[5]
	set_location_assignment PIN_K6 -to vga_r[0]
	set_location_assignment PIN_K5 -to vga_r[1]
	set_location_assignment PIN_L7 -to vga_r[2]
	set_location_assignment PIN_L3 -to vga_r[3]
	set_location_assignment PIN_L4 -to vga_r[4]
	set_location_assignment PIN_E1 -to clk_50m
	set_location_assignment PIN_N13 -to btn_rst_n
	set_location_assignment PIN_M15 -to btn_fire
	set_location_assignment PIN_E16 -to btn_up
	set_location_assignment PIN_M16 -to btn_dn
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}
