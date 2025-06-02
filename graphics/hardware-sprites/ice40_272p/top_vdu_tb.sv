`default_nettype none
`timescale 1ns / 1ps

module top_vdu_tb();

localparam CLK_PERIOD = 2;  // 10 ns == 100 MHz
localparam FONT_F = "../res/sprites/TI-83.mem";

localparam H_RES = 480;
localparam V_RES = 272;

logic rst_n;
logic clk;

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

logic line = 0;
logic [15:0] sx = 0;
logic [15:0] sy = 0;

// VDU
logic read_en;
logic [15:0] read_addr;
logic [7:0] display_data;
logic [7:0] font_rom_data;
logic drawing;  // drawing at (sx,sy)

rom_async #(
	.WIDTH(8),
	.DEPTH(8 * 64),
	.INIT_F(FONT_F),
	.BIN_MODE(1)
)
font_rom(
	.addr(display_data),
	.data(font_rom_data)
);


vdu #(
	.BASE_ADDR(0),
	.SCALE(1),
	.FONT_F(FONT_F),
	.X_OFFSET(30),
	.Y_OFFSET(30)
)
vdu_inst (
	.i_clk(clk),
	.i_en(1),
	.i_frame(0),
	.i_line(line),
	.i_sx(sx),
	.i_sy(sy),
	.o_read_en(read_en),
	.o_read_addr(read_addr),
	.i_display_data(display_data),
	.o_drawing(drawing)
);

initial begin
	$dumpfile("top_vdu_tb.vcd");
	$dumpvars(0, top_vdu_tb);
	rst_n = 0;
	clk = 1;
	//$display("rst_n %b", rst_n);

	#2 rst_n = 1;

	#2 line = 1;
	sy = 30;


	//$display("rst_n %b", rst_n);

	#8000 $finish;
end

always_comb begin
	display_data = read_addr;
end

always_ff @(posedge clk) begin
	line <= 0;
	sx <= sx + 1;
	if (sx >= H_RES) begin
		sx <= 0;
		sy <= sy + 1;
		if (sy >= V_RES) begin
			sy <= 0;
		end
	end
end

endmodule
