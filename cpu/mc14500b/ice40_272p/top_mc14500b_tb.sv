`default_nettype none
`timescale 1ns / 1ps

`include "instructions.svh"

module top_mc14500b_tb();

	parameter CLK_PERIOD = 2;  // 10 ns == 100 MHz

logic	RST;
logic	X2;
logic	[3:0] INSTR;
logic	DATA_IN;
logic	DATA_OUT;
logic	X1;
logic	RR;
logic	WRITE;
logic	JMP;
logic	RTN;
logic	FLG0;
logic	FLGF;

mc14500b mc14500b_inst (.RST, .X2, .INSTR, .DATA_IN, .DATA_OUT, .X1, .RR, .WRITE, .JMP, .RTN, .FLG0, .FLGF);

// generate clock
always #(CLK_PERIOD / 2) X2 <= ~X2;

initial begin
	$dumpfile("top_mc14500b_tb.vcd");
	$dumpvars(0, top_mc14500b_tb);
	DATA_IN = 0;
	RST = 1;
	X2 = 1;
	DATA_IN = 1;

	#4 RST = 0;

	#2 INSTR = `I_ORC;

	#2 INSTR = `I_IEN;
	#2 INSTR = `I_OEN;

	#2 INSTR = `I_NOP0;

	#2 INSTR = `I_LD;
	DATA_IN = 1;

	#2 INSTR = `I_LD;
	DATA_IN = 0;

	#2 INSTR = `I_LDC;
	DATA_IN = 1;

	#2 INSTR = `I_LDC;
	DATA_IN = 0;

	#2 INSTR = `I_AND;
	DATA_IN = 1;

	#2 INSTR = `I_AND;
	DATA_IN = 0;

	#2 INSTR = `I_ANDC;
	DATA_IN = 1;

	#2 INSTR = `I_ANDC;
	DATA_IN = 0;

	#2 INSTR = `I_OR;
	DATA_IN = 1;

	#2 INSTR = `I_OR;
	DATA_IN = 0;

	#2 INSTR = `I_STO;
	DATA_IN = 0;

	#2 INSTR = `I_STOC;
	DATA_IN = 0;

	#2 INSTR = `I_JMP;
	DATA_IN = 0;

	#2 INSTR = `I_RTN;
	DATA_IN = 0;

	#2 INSTR = `I_NOPF; // this is skipped after RTN

	#2 INSTR = `I_SKZ;
	DATA_IN = 0;

	//#2 INSTR = `I_NOPF;
	DATA_IN = 0;

	#2 $finish;
end

logic _unused_ok = &{1'b1, X1, RR, WRITE, JMP, RTN, FLG0, FLGF, 1'b0};

endmodule
