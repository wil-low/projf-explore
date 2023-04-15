`default_nettype none
`timescale 1ns / 1ps

module top_fifo_tb();

parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
localparam WIDTH = 8;
localparam DEPTH = 4;

logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic rst_n = 1;					// reset

logic push_en = 0;					// push enable (port a)
logic [WIDTH-1:0] push_data;		// data to push (port a)

logic pop_en = 0;			  		// pop enable (port a)
logic [WIDTH-1:0] pop_data; 		// data to pop (port b)

logic full;					// buffer is full
logic empty;					// buffer is empty

fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH))
fifo_inst(
	.clk, .rst_n,
	.push_en, .push_data, .pop_en, .pop_data,
	.full, .empty
);

assert (!(push_en && full));// else $error("Assertion full_test failed (push %d)", push_data);
assert (!(pop_en && empty));// else $error("Assertion empty_test failed!");

initial begin
	$dumpfile("top_fifo_tb.vcd");
	$dumpvars(0, top_fifo_tb);
	clk = 1;

	#CLK_PERIOD rst_n = 0;
	#CLK_PERIOD rst_n = 1;

	#CLK_PERIOD;
	push_data = 1;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 2;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 3;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 4;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 5;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 6;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 7;
	push_en = 1;

	#CLK_PERIOD;
	push_data = 0;
	push_en = 0;

	#CLK_PERIOD;
	pop_en = 1;

	#(CLK_PERIOD * 20) $finish;
end

endmodule
