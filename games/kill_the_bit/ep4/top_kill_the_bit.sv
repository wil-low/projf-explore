`default_nettype none
`timescale 1ns / 1ps

module top_kill_the_bit
(
	input wire CLK,
	input wire rst_n,
	
	output logic LK_CLK,
	inout  wire  LK_DIO,
	output logic LK_STB,
	
	output logic [7:0] LED
);

kill_the_bit
#(
	.CLOCK_FREQ_MHz(50)
)
kill_the_bit_inst
(
	.i_clk(CLK),
	.rst_n(rst_n),
	.o_ledkey_clk(LK_CLK),
	.o_ledkey_stb(LK_STB),
	.io_ledkey_dio(LK_DIO),
	.o_LED(LED)
);

wire _unused_ok = &{1'b1, 1'b0};

endmodule
