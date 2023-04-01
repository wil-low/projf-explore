`default_nettype none
`timescale 1ns / 1ps

`include "instructions.sv"

module top_mc14500b_tb();
	parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
 	logic	RST;
	logic	X2;
	logic	[3:0] INSTR;
	wire	DATA;
	logic	X1;
	logic	RR;
	logic	WRITE;
	logic	JMP;
	logic	RTN;
	logic	FLG0;
	logic	FLGF;

	logic	data_in;

	assign DATA = data_in;

    mc14500b mc14500b_inst (.RST, .X2, .INSTR, .DATA, .X1, .RR, .WRITE, .JMP, .RTN, .FLG0, .FLGF);

    // generate clock
    always #(CLK_PERIOD / 2) X2 <= ~X2;

    initial begin
		$dumpfile("top_mc14500b_tb.vcd");
        $dumpvars(0, top_mc14500b_tb);
		data_in = 0;
        RST = 1;
        X2 = 1;
		data_in = 1;

        #100 RST = 0;

		//#100 INSTR = `I_IEN;

		#100 INSTR = `I_NOP0;

		#100 INSTR = `I_LD;
		data_in = 1;

		#100 INSTR = `I_LD;
		data_in = 0;

		#100 INSTR = `I_LDC;
		data_in = 1;

		#100 INSTR = `I_LDC;
		data_in = 0;

		#100 INSTR = `I_AND;
		data_in = 1;

		#100 INSTR = `I_AND;
		data_in = 0;

		#100 INSTR = `I_ANDC;
		data_in = 1;

		#100 INSTR = `I_ANDC;
		data_in = 0;

		#100 INSTR = `I_OR;
		data_in = 1;

		#100 INSTR = `I_OR;
		data_in = 0;

		#100 INSTR = `I_STO;
		data_in = 0;

		#100 INSTR = `I_NOP0;

        #300 $finish;
    end

logic _unused_ok = &{1'b1, X1, RR, WRITE, JMP, RTN, FLG0, FLGF, 1'b0};

endmodule
