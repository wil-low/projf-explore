`default_nettype none
`timescale 1ns / 1ps

module top_mk14
(
	input wire logic CLK,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4,

	output logic PROBE,

	output logic LK_CLK,
	output logic LK_STB,
	inout  wire  LK_DIO,

	input wire IR
);

//// Reset emulation
logic [22:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

logic [7:0] trace;
assign LED = ~trace;

localparam CLOCK_FREQ_MHZ = 50;

localparam ROM_INIT_F		= "SCIOS_Version_2.mem";
localparam STD_RAM_INIT_F	= "collatz.mem";
//localparam STD_RAM_INIT_F	= "test.mem";
localparam EXT_RAM_INIT_F	= "ext_ram.mem";

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
	.ir(IR)
);

endmodule
