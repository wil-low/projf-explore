`default_nettype none
`timescale 1ns / 1ps

module top_charlieplex
(
	input wire CLK,
	inout  wire [2:0] io_pin
);

//// Reset emulation for ice40
logic [7:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

charlieplex
#(
	.CLOCK_FREQ_MHz(12)
)
charlieplex_inst
(
	.i_clk(CLK),
	.io_pin
);

wire _unused_ok = &{1'b1, 1'b0};

endmodule
