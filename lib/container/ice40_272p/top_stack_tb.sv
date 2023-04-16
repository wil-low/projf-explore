`default_nettype none
`timescale 1ns / 1ps

module top_stack_tb();

parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
localparam WIDTH = 8;
localparam STACK_DEPTH = 4;

logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic stack_rst_n = 1;
logic stack_push_en = 0;			// push enable (add on top)
logic stack_pop_en = 0;				// pop enable (remove from top)
logic stack_peek_en = 0;			// peek enable (return item at index, no change)
logic stack_poke_en = 0;			// poke enable (replace item at index)
logic [55:0] stack_data_in;			// data to push|poke
logic [55:0] stack_data_out; 		// data returned for pop|peek
logic stack_full;					// buffer is full
logic stack_empty;					// buffer is empty
logic [$clog2(STACK_DEPTH):0] stack_index;  // element index t (0 is top)
logic [$clog2(STACK_DEPTH):0] stack_depth;  // returns how many items are in stack

stack #(.WIDTH(8), .DEPTH(STACK_DEPTH))
stack_inst(
	.clk,
	.rst_n(stack_rst_n),
	.push_en(stack_push_en),
	.pop_en(stack_pop_en),
	.peek_en(stack_peek_en),
	.poke_en(stack_poke_en),
	.index(stack_index),
	.data_in(stack_data_in),
	.data_out(stack_data_out),
	.full(stack_full),
	.empty(stack_empty),
	.depth(stack_depth)
);

initial begin
	$dumpfile("top_stack_tb.vcd");
	$dumpvars(0, top_stack_tb);
	clk = 1;
	stack_push_en = 0;
	stack_pop_en = 0;

	stack_rst_n = 1;
	#CLK_PERIOD stack_rst_n = 0;
	#CLK_PERIOD stack_rst_n = 1;

	#CLK_PERIOD;
	stack_data_in = 1;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_data_in = 2;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_data_in = 3;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_data_in = 4;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_data_in = 5;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_data_in = 6;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_data_in = 7;
	stack_push_en = 1;

	#CLK_PERIOD;
	stack_push_en = 0;

	#CLK_PERIOD;
	stack_index = 0;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 1;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 2;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 3;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 4;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_peek_en = 0;

	#CLK_PERIOD;
	stack_index = 1;
	stack_data_in = 'hff;
	stack_poke_en = 1;

	#CLK_PERIOD;
	stack_poke_en = 0;
	stack_index = 1;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 0;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 1;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 2;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 3;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_index = 4;
	stack_peek_en = 1;

	#CLK_PERIOD;
	stack_peek_en = 0;
	
	#CLK_PERIOD;
	stack_rst_n = 0;

	#CLK_PERIOD;
	stack_rst_n = 1;

	#300 $finish;
end

endmodule
