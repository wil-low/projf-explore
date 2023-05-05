`default_nettype none
`timescale 1ns / 1ps

module top_charlieplex
(
	input wire CLK,
	inout  wire [2:0] io_pin
);

charlieplex
#(
	.CLOCK_FREQ_MHz(50)
)
charlieplex_inst
(
	.i_clk(CLK),
	.io_pin
);

wire _unused_ok = &{1'b1, 1'b0};

endmodule
