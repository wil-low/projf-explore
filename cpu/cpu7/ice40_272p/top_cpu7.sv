`default_nettype none
`timescale 1ns / 1ps

module top_cpu7
(
	input clk
);

//// Reset emulation for ice40
logic [22:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge clk) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end


logic _unused_ok = &{1'b1, 1'b0};

endmodule
