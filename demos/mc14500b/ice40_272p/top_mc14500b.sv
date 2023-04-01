`default_nettype none
`timescale 1ns / 1ps

module top_mc14500b (
	input RST,
	input X2,
	input [3:0] INSTR,
	inout DATA,
	output X1,
	output RR,
	output WRITE,
	output JMP,
	output RTN,
	output FLG0,
	output FLGF
);

	mc14500b mc14500b_inst(.RST, .X2, .INSTR, .DATA, .X1, .RR, .WRITE, .JMP, .RTN, .FLG0, .FLGF);

endmodule
