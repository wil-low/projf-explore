`default_nettype none
`timescale 1ns / 1ps

`include "../instructions.svh"

module top_mc14500b_demo (
	input CLK,
	input BTN1,
	input BTN2,
	input BTN3,
	output [7:0] LED
);

//// Reset emulation for ice40
logic [7:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

logic [7:1] btn;

/* verilator lint_off PINCONNECTEMPTY */
debounce debounce_inst0 (
	.clk(CLK),
	.in(BTN1),
	.out(btn[1]),
	.ondn(),
	.onup()
);

debounce debounce_inst1 (
	.clk(CLK),
	.in(BTN2),
	.out(btn[2]),
	.ondn(),
	.onup()
);

debounce debounce_inst2 (
	.clk(CLK),
	.in(BTN3),
	.out(btn[3]),
	.ondn(),
	.onup()
);
/* verilator lint_on PINCONNECTEMPTY */

mc14500b_demo #("cmd.mem")
	mc14500b_demo_inst (.RST(~rst_n), .CLK(CLK), .INPUT(btn), .OUTPUT(LED));

logic _unused_ok = &{1'b1, btn[7:4], 1'b0};

endmodule
