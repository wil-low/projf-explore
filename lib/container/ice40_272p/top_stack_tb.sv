`default_nettype none
`timescale 1ns / 1ps

module top_stack_tb();

parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
localparam WIDTH = 8;
localparam DEPTH = 4;

logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic rst_n;						// reset

logic push_en = 0;					// push enable (port a)
logic [WIDTH-1:0] push_data;		// data to push (port a)

logic pop_en = 0;		  			// pop enable (port a)
logic [WIDTH-1:0] pop_data; 		// data to pop (port b)

wire logic full;					// buffer is full
wire logic empty;					// buffer is empty

stack #(.WIDTH(WIDTH), .DEPTH(DEPTH))
stack_inst(
	.clk_write(clk), .clk_read(clk), .rst_n(rst_n),
	.push_en, .push_data, .pop_en, .pop_data,
	.full, .empty
);

initial begin
	$dumpfile("top_stack_tb.vcd");
	$dumpvars(0, top_stack_tb);
	clk = 1;
	push_en = 0;
	pop_en = 0;

	rst_n = 1;
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

	#300 $finish;
end

endmodule
