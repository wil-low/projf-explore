`default_nettype none
`timescale 1ns / 1ps

module top_mk14
(
	input wire logic CLK,
	input wire logic rst_n,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4,

	output logic PROBE,

	output logic LK_CLK,
	output logic LK_STB,
	inout  wire  LK_DIO
);

logic [7:0] trace;
logic [8 * 8 - 1:0] display;

//assign LED[0] = |display[0 * 8 + 7 -: 8];
//assign LED[1] = |display[1 * 8 + 7 -: 8];
//assign LED[2] = |display[2 * 8 + 7 -: 8];
//assign LED[3] = |display[3 * 8 + 7 -: 8];
//assign LED[4] = |display[4 * 8 + 7 -: 8];
//assign LED[5] = |display[5 * 8 + 7 -: 8];
//assign LED[6] = |display[6 * 8 + 7 -: 8];
//assign LED[7] = |display[7 * 8 + 7 -: 8];

assign LED = ~trace;

mk14_soc #(
	.CLOCK_FREQ_MHZ(50),
	.INIT_F("../../programs/display.mem")
)
mk14_soc_inst (
	.rst_n,
	.clk(CLK),
	.trace,
	.probe(PROBE),
	.o_ledkey_clk(LK_CLK),
	.o_ledkey_stb(LK_STB),
	.io_ledkey_dio(LK_DIO)
);

endmodule
