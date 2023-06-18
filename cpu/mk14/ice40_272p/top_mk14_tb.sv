`default_nettype none
`timescale 1ns / 1ps

module top_mk14_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz

localparam ROM_INIT_F		= "../programs/SCIOS_Version_2.mem";
//localparam ROM_INIT_F		= "../programs/display.mem";
localparam STD_RAM_INIT_F	= "../ext_ram.mem";
localparam EXT_RAM_INIT_F	= "../ext_ram.mem";

localparam FONT_F			= "../vdu/TI-83.mem";
localparam DISP_RAM_INIT_F	= "../vdu/disp_mem.mem";

logic rst_n;
logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic [7:0] trace;
logic IR;

logic lk_clk;
logic lk_stb;
logic lk_dio;

logic btn_dn = 0;
logic btn_up = 0;
logic [2:0] btn_addr;
logic [2:0] btn_bit;

mk14_soc #(
	.CLOCK_FREQ_MHZ(1),
	.DISPLAY_REFRESH_MSEC(5),
	.ROM_INIT_F(ROM_INIT_F),
	.STD_RAM_INIT_F(STD_RAM_INIT_F),
	.EXT_RAM_INIT_F(EXT_RAM_INIT_F),
	.VDU_FONT_F(FONT_F),
	.VDU_RAM_F(DISP_RAM_INIT_F),
	.VDU_BASE_ADDR('h0200)
)
mk14_soc_inst (
	.rst_n,
	.clk,
	.trace,
	.o_ledkey_clk(lk_clk),
	.o_ledkey_stb(lk_stb),
	.io_ledkey_dio(lk_dio),
	.ir(IR),
	.btn_dn,
	.btn_up,
	.btn_addr,
	.btn_bit,

	.clk_pix(clk),
	.rst_pix(1)
);

initial begin
	$dumpfile("top_mk14_tb.vcd");
	$dumpvars(0, top_mk14_tb);
	rst_n = 0;
	clk = 1;
	//$display("rst_n %b", rst_n);

	#20 rst_n = 1;
/*
	#1920;  // F
	btn_dn = 1;
	btn_up = 0;
	btn_addr = 1;
	btn_bit = 4;
	#2250;
	btn_dn = 0;
	btn_up = 1;
	#50 $display("Press B");

	#10000;  // 2
	btn_dn = 1;
	btn_up = 0;
	btn_addr = 0;
	btn_bit = 7;
	#2250;
	btn_dn = 0;
	btn_up = 1;
	#50 $display("Press 0");

	#10000;  // 0
	btn_dn = 1;
	btn_up = 0;
	btn_addr = 0;
	btn_bit = 7;
	#2250;
	btn_dn = 0;
	btn_up = 1;
	#50 $display("Press 0");

	#10000;  // GO
	btn_dn = 1;
	btn_up = 0;
	btn_addr = 2;
	btn_bit = 5;
	#2250;
	btn_dn = 0;
	btn_up = 1;
	#50 $display("Press GO");

	//$display("rst_n %b", rst_n);
*/
	#80000 $finish;
end

endmodule
