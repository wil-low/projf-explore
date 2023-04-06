`default_nettype none
`timescale 1ns / 1ps

`include "instructions.svh"
`include "cmd.mem.svh"

module top_mc14500b_demo_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz

logic	RST;
logic	X2;
logic [7:1] INPUT = 0;
logic [7:0] OUTPUT;
logic [7:0] TRACE;

// generate clock
always #(CLK_PERIOD / 2) X2 <= ~X2;

mc14500b_demo #(
	.INIT_F("cmd.mem"),
	.START_ADDRESS(`CmdFPGA),
	.FLG0_HALT(1'b0),
	.FLGF_LOOP(1'b1)
)
mc14500b_demo_inst (
	.RST,
	.CLK(X2),
	.INPUT,
	.OUTPUT,
	.TRACE
);

initial begin
	$dumpfile("top_mc14500b_demo_tb.vcd");
	$dumpvars(0, top_mc14500b_demo_tb);
	RST = 1;
	X2 = 1;

	#4 RST = 0;

	#50 $finish;
end

logic _unused_ok = &{1'b1, OUTPUT, 1'b0};

endmodule
