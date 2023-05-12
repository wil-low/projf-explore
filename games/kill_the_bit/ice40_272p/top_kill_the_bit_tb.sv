//-------------------------------------------------------------------
//-- default_tb.v
//-------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module top_kill_the_bit_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz
logic CLK = 1;
always #(CLK_PERIOD / 2) CLK <= ~CLK;

logic start = 0;
logic [7:0] command = 0;

logic LK_CLK;
logic LK_DIO;
logic LK_STB;

logic [7:0] LED;

logic rst_n;

kill_the_bit
#(
	.CLOCK_FREQ_MHz(12)
)
kill_the_bit_inst
(
	.i_clk(CLK),
	.rst_n(rst_n),
	.o_ledkey_clk(LK_CLK),
	.o_ledkey_stb(LK_STB),
	.io_ledkey_dio(LK_DIO),
	.o_LED(LED)
);

localparam COUNTER_LIMIT = 200;

logic [31:0] counter = COUNTER_LIMIT - 5;
//logic [2:0] state = 0;

initial begin
	$dumpfile("top_kill_the_bit_tb.vcd");
	$dumpvars(0, top_kill_the_bit_tb);
	rst_n = 0;

	//$monitor("[mon] start %b, command %b, clock %b, strobe %b, data %b", start, command, LK_CLK, LK_STB, LK_DIO);

	#10 rst_n = 1;
/*
	#10 start = 1;
		command = 8'h8f;
	#2  start = 0;

	#80 start = 1;
		command = 8'h80;
	#2	start = 0;
*/
	//#80 $finish;
end

always @(posedge CLK) begin
	#640000 $finish;
end

wire _unused_ok = &{1'b1, LK_CLK, LK_DIO, LK_STB, counter, LED, 1'b0};

endmodule
