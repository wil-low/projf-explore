// CPU7 one core module

`default_nettype none
`timescale 1ns / 1ps

//`include "instructions.svh"

module core
(
	input logic rst_n,
	input logic clk,
	input logic en,					// core is selected to run
	input logic [55:0] push_value,	// constant value to push on stack
	input logic push_en,			// do push
	input logic [13:0] instr,		// instruction to execute
	input logic instr_en,			// do execute
	input logic pcp_step_en,		// advance pcp by 2
	output logic [27:0] pcp,		// program code pointer (...0)
	output logic executing			// core status by condition action register
);

localparam VREGS = 8;  // number of V-registers in this realisation

logic [27:0] car; // conditional action register
					// only the two lowest order bits are monitored to determine the current condition
logic [27:0] r_a; // register R0 (A)
logic [27:0] r_b; // register R1 (B)
logic [27:0] r_c; // register R2 (C)
logic [13:0] r_d; // register R3 (D)
logic [13:0] r_e; // register R3 (E)

logic [13:0] icr; // instruction code register
					// contains two 7-bit instruction codes with the one in the lower
					// 7 bits executed first, and the one in the higher 7 bits executed second
logic [13:0] csp; // call stack pointer
logic [13:0] dsp; // data stack pointer
logic [13:0] dsp_s; // data stack pointer snapshot
logic [13:0] ddc; // data stack depth counter
logic [13:0] ddc_s; // data stack depth counter snapshot
logic [13:0] ppr; // process priority register

logic [27:0] dcr; // delay compare register, kept 0 if there is no active delay, otherwise contains the compare
logic [27:0] v_r[VREGS]; // variable registers

assign executing = ((car & `CA_MASK) == `CA_NONE) || ((car & `CA_MASK) == `CA_EXEC);

always @(posedge clk) begin
	if (rst_n) begin
		//{RR, JMP, RTN, FLG0, FLGF, WRITE, skz, ien, oen, DATA_OUT} <= 0;
		$display("RESET");
	end
	else if (en) begin
	end

end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
