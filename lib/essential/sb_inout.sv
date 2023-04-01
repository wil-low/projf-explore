`default_nettype none
`timescale 1ns / 1ps

// Implementation of tristateable output.
module sb_inout(
	inout pin,
	input out_enable,
	input out_value,
	output in_value
);

assign pin = out_enable ? out_value : 1'bz;
assign in_value = pin === 1'b1;

endmodule
