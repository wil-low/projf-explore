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
assign LED = ~trace;

localparam CLOCK_FREQ_MHZ = 50;

//localparam ROM_INIT_F		= "../../SCIOS_Version_2.mem";
localparam ROM_INIT_F		= "../../programs/display.mem";
localparam STD_RAM_INIT_F	= "../../programs/test.mem";
localparam EXT_RAM_INIT_F	= "../../ext_ram.mem"

mk14_soc #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ),
	.DISPLAY_TIMEOUT_CYCLES(CLOCK_FREQ_MHZ * 1000 * 100),
	.ROM_INIT_F(ROM_INIT_F),
	.STD_RAM_INIT_F(STD_RAM_INIT_F),
	.EXT_RAM_INIT_F(EXT_RAM_INIT_F)
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
