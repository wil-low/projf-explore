`default_nettype none
`timescale 1ns / 1ps

// Implementation of tristateable output.
module sb_inout(
	inout wire pin,
	input wire out_enable,
	input wire out_value,
	output wire in_value
);

IOBUF #(
   .DRIVE(12), // Specify the output drive strength
   .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
   .IOSTANDARD("DEFAULT"), // Specify the I/O standard
   .SLEW("SLOW") // Specify the output slew rate
) IOBUF_inst (
   .O(in_value),     // Buffer output
   .IO(pin),   // Buffer inout port (connect directly to top-level port)
   .I(out_value),     // Buffer input
   .T(~out_enable)      // 3-state enable input, high=input, low=output
);

endmodule
