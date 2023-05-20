`default_nettype none
`timescale 1ns / 1ps

module top_mk14_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz

localparam ROM_INIT_F		= "../programs/SCIOS_Version_2.mem";
//localparam ROM_INIT_F		= "../programs/display.mem";
localparam STD_RAM_INIT_F	= "../programs/test.mem";
localparam EXT_RAM_INIT_F	= "../ext_ram.mem";

logic rst_n;
logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic [7:0] trace;
logic [8 * 8 - 1:0] display;

logic lk_clk;
logic lk_stb;
logic lk_dio;

logic btn_dn = 0;
logic btn_up = 0;

mk14_soc #(
	.CLOCK_FREQ_MHZ(1),
	.DISPLAY_TIMEOUT_CYCLES(5),
	.ROM_INIT_F(ROM_INIT_F),
	.STD_RAM_INIT_F(STD_RAM_INIT_F),
	.EXT_RAM_INIT_F(EXT_RAM_INIT_F)
)
mk14_soc_inst (
	.rst_n,
	.clk,
	.trace,
	.o_ledkey_clk(lk_clk),
	.o_ledkey_stb(lk_stb),
	.io_ledkey_dio(lk_dio),
	.btn_dn,
	.btn_up
);

initial begin
	$dumpfile("top_mk14_tb.vcd");
	$dumpvars(0, top_mk14_tb);
	rst_n = 0;
	clk = 1;
	//$display("rst_n %b", rst_n);

	#2 rst_n = 1;

	#1920;
	btn_dn = 1;
	btn_up = 0;

	#250;
	btn_dn = 0;
	btn_up = 1;

	#100;
	btn_dn = 0;
	btn_up = 0;

	//$display("rst_n %b", rst_n);

	#20000 $finish;
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
