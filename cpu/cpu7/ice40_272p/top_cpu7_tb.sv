`default_nettype none
`timescale 1ns / 1ps

//`include "instructions.svh"
//`include "cmd.mem.svh"

module top_cpu7_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz
localparam INIT_F = "../test.mem";

logic rst_n;
logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

cpu7_soc #(
	.CORES(4), .PROGRAM_SIZE(1024), .VREGS(8),
	.DATA_STACK_DEPTH(8), .CALL_STACK_DEPTH(8),
	.INIT_F(INIT_F)
)
cpu7_soc_inst (.rst_n, .clk);

initial begin
	$dumpfile("top_cpu7_tb.vcd");
	$dumpvars(0, top_cpu7_tb);
	rst_n = 0;
	clk = 1;
	//$display("rst_n %b", rst_n);

	#2 rst_n = 1;

	#2;
	//$display("rst_n %b", rst_n);

	#2000 $finish;
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
