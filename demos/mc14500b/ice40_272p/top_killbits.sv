`default_nettype none
`timescale 1ns / 1ps

`include "../instructions.svh"
`include "cmd.mem.svh"

module top_killbits 
(
	input CLK,
	input BTN1,
	input BTN2,
	input BTN3,
	output [7:0] LED,
	output LED1,
	output LED2,
	output LED3,
	output LED4
);

//// Reset emulation for ice40
logic [22:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

logic [7:1] inputs;
assign inputs[7:4] = 4'b1111;

/* verilator lint_off PINCONNECTEMPTY */
debounce debounce_inst0 (
	.clk(CLK),
	.in(BTN1),
	.out(inputs[1]),
	.ondn(),
	.onup()
);

debounce debounce_inst1 (
	.clk(CLK),
	.in(BTN2),
	.out(inputs[2]),
	.ondn(),
	.onup()
);

debounce debounce_inst2 (
	.clk(CLK),
	.in(BTN3),
	.out(inputs[3]),
	.ondn(),
	.onup()
);
/* verilator lint_on PINCONNECTEMPTY */

wire [7:0] out;
assign LED = ~out;
assign {LED1, LED2, LED3, LED4} = ~0;


wire [7:0] trace;
/*
assign LED = ~trace;
assign LED1 = ~out[0];
assign LED2 = ~out[1];
assign LED3 = ~out[2];
assign LED4 = ~out[3];
*/

localparam CLOCK_DIVIDER = 13;

logic [CLOCK_DIVIDER:0] counter = 0;
logic X2 = 1;

always @(posedge CLK) begin
	if (counter == 0)
		X2 <= ~X2;
	counter <= counter + 1;
end

mc14500b_demo #(
	.INIT_F("cmd.mem"),
	.START_ADDRESS(`CmdKillbits),
	//.START_ADDRESS(`CmdBranchTest),
	.FLG0_HALT(1'b0),
	.FLGF_LOOP(1'b1)
)
mc14500b_demo_inst (
	.RST(~rst_n),
	.CLK(X2),
	.INPUT(inputs),
	.OUTPUT(out),
	.TRACE(trace)
);

logic _unused_ok = &{1'b1, 1'b0};

endmodule
