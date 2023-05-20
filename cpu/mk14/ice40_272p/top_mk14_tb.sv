`default_nettype none
`timescale 1ns / 1ps

module top_mk14_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz

localparam ROM_INIT_F		= "../programs/SCIOS_Version_2.mem";
//localparam ROM_INIT_F		= "../programs/test.mem";
localparam STD_RAM_INIT_F		= "../programs/segtris_p1.mem";
//localparam STD_RAM_INIT_F	= "../programs/clock.mem";
//localparam STD_RAM_INIT_F	= "../programs/test.mem";
//localparam EXT_RAM_INIT_F	= "../ext_ram.mem";
localparam EXT_RAM_INIT_F	= "../programs/segtris_p2.mem";

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
	.ir(IR),
	.btn_dn,
	.btn_up,
	.btn_addr,
	.btn_bit
);

initial begin
	$dumpfile("top_mk14_tb.vcd");
	$dumpvars(0, top_mk14_tb);
	rst_n = 0;
	clk = 1;
	//$display("rst_n %b", rst_n);

	#2 rst_n = 1;

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

	#800000 $finish;
end

/*
logic carry_in = 1;
logic [7:0] a = 'h55;
logic [7:0] b = 'h44;

logic [7:0] sum = 0;
logic carry_out = 0;

always @(posedge clk) begin
	if (a[3:0] + b[3:0] + carry_in > 9) begin
		sum[3:0] <= a[3:0] + b[3:0] + carry_in + 6;
		if (a[7:4] + b[7:4] + 1 > 9)
			{carry_out, sum[7:4]} <= a[7:4] + b[7:4] + 6 + 1;
		else
			{carry_out, sum[7:4]} <= a[7:4] + b[7:4] + 1;
	end
	else begin
		sum[3:0] <= a[3:0] + b[3:0] + carry_in;
		if (a[7:4] + b[7:4] > 9)
			{carry_out, sum[7:4]} <= a[7:4] + b[7:4] + 6;
		else
			{carry_out, sum[7:4]} <= a[7:4] + b[7:4];
	end
	$display("BCD %h add %h (c %b) = %h (c %b)", a, b, carry_in, sum, carry_out);
end
*/

endmodule
