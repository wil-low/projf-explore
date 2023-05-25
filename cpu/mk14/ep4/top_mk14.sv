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
	inout  wire  LK_DIO,
	
	input wire IR,
	input wire RX
);

logic [7:0] trace;
assign LED = trace;

logic rx_wait;
assign LED1 = ~rx_wait;

localparam CLOCK_FREQ_MHZ = 50;

localparam ROM_INIT_F		= "../../programs/SCIOS_Version_2.mem";
//localparam ROM_INIT_F		= "../../programs/display.mem";
localparam STD_RAM_INIT_F	= "../../programs/collatz.mem";
//localparam STD_RAM_INIT_F	= "../../programs/clock.mem";
//localparam STD_RAM_INIT_F	= "../../programs/test.mem";
//localparam EXT_RAM_INIT_F	= "../../ext_ram.mem";
localparam EXT_RAM_INIT_F	= "../../programs/segtris_p2.mem";

mk14_soc #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ),
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
	.io_ledkey_dio(LK_DIO),
	.ir(IR),
	.sin(),
	.sout(),
	.rx(RX),
	.rx_wait
);

endmodule
