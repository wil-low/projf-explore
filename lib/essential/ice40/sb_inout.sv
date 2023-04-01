`default_nettype none
`timescale 1ns / 1ps

// Implementation of tristateable output.
module sb_inout(
	inout pin,
	input out_enable,
	input out_value,
	output in_value
);

SB_IO #(
	.PIN_TYPE(6'b 1010_01),
	.PULLUP(1'b 0)
) sb_io (
	.PACKAGE_PIN(pin),
	.OUTPUT_ENABLE(out_enable),
	.D_OUT_0(out_value),
	.D_IN_0(in_value)
);

endmodule
