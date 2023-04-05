`default_nettype none
`timescale 1ns / 1ps

`include "instructions.svh"

module top_mc14500b_demo_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz

logic	RST;
logic	X2;
logic [7:1] INPUT = 7'b1;
logic [7:0] OUTPUT;

// generate clock
always #(CLK_PERIOD / 2) X2 <= ~X2;

mc14500b_demo #("cmd.mem")
	mc14500b_demo_inst (.RST, .CLK(X2), .INPUT, .OUTPUT);

initial begin
	$dumpfile("top_mc14500b_demo_tb.vcd");
	$dumpvars(0, top_mc14500b_demo_tb);
	RST = 1;
	X2 = 1;

	#4 RST = 0;

	#100 $finish;
end

logic _unused_ok = &{1'b1, OUTPUT, 1'b0};

endmodule
