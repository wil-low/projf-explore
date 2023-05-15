`default_nettype none
`timescale 1ns / 1ps

module top_mk14_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz
localparam INIT_F = "../programs/collatz.mem";

logic rst_n;
logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic [7:0] trace;
logic [8 * 8 - 1:0] display;

mk14_soc #(
	.CLOCK_FREQ_MHZ(1),
	.INIT_F(INIT_F)
)
mk14_soc_inst (
	.rst_n,
	.clk,
	.trace,
	.display
);

initial begin
	$dumpfile("top_mk14_tb.vcd");
	$dumpvars(0, top_mk14_tb);
	rst_n = 0;
	clk = 1;
	//$display("rst_n %b", rst_n);

	#2 rst_n = 1;

	#2;
	//$display("rst_n %b", rst_n);

	#100000 $finish;
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
