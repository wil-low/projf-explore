// Project F Library - Simple Quadruple-Port Block RAM
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module bram_sqp #(
	parameter WIDTH = 8, 
	parameter DEPTH = 256, 
	parameter INIT_F = ""
)
(
	input wire logic clk,								// common clock

	input wire logic we0,								// write enable (port 0)
	input wire logic [$clog2(DEPTH)-1:0] addr_write0,	// write address (port 0)
	input wire logic [$clog2(DEPTH)-1:0] addr_read0,	// read address (port 0)
	input wire logic [WIDTH-1:0] data_in0,	 			// data in (port 0)
	output     logic [WIDTH-1:0] data_out0,	 			// data out (port 0)

	input wire logic we1,								// write enable (port 1)
	input wire logic [$clog2(DEPTH)-1:0] addr_write1,	// write address (port 1)
	input wire logic [$clog2(DEPTH)-1:0] addr_read1,	// read address (port 1)
	input wire logic [WIDTH-1:0] data_in1,	 			// data in (port 1)
	output     logic [WIDTH-1:0] data_out1	 			// data out (port 1)
);

	(* ramstyle="no_rw_check" *) logic [WIDTH-1:0] memory [DEPTH];

	initial begin
		if (INIT_F != 0) begin
			$display("Loading memory init file '%s' into bram_sdp.", INIT_F);
			$readmemh(INIT_F, memory);
		end
	end

	// Port 0
	always_ff @(posedge clk) begin
		if (we0)
			memory[addr_write0] <= data_in0;
		data_out0 <= memory[addr_read0];
	end

	// Port 1
	always_ff @(posedge clk) begin
		if (we1)
			memory[addr_write1] <= data_in1;
		data_out1 <= memory[addr_read1];
	end
endmodule
