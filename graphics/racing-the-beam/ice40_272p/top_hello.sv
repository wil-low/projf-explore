// Project F: Racing the Beam - Hello (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hello (
	input  wire logic clk_12m,	  // 12 MHz clock
	input  wire logic btn_rst,	  // reset button
	output	  logic vga_clk,	  // VGA pixel clock
	output	  logic vga_hsync,	// VGA horizontal sync
	output	  logic vga_vsync,	// VGA vertical sync
	output	  logic vga_de,	   // VGA data enable
	output	  logic [4:0] vga_r,  // 5-bit VGA red
	output	  logic [5:0] vga_g,  // 6-bit VGA green
	output	  logic [4:0] vga_b   // 5-bit VGA blue
	);

	// generate pixel clock
	logic clk_pix;
	logic clk_pix_locked;
	clock_272p clock_pix_inst (
	   .clk_12m,
	   .rst(btn_rst),
	   .clk_pix,
	   .clk_pix_locked
	);

	// display sync signals and coordinates
	localparam CORDW = 10;  // screen coordinate width in bits
	/* verilator lint_off UNUSED */
	logic [CORDW-1:0] sx, sy;
	/* verilator lint_on UNUSED */
	logic hsync, vsync, de;
	simple_272p display_inst (
		.clk_pix,
		.rst_pix(!clk_pix_locked),  // wait for clock lock
		.sx,
		.sy,
		.hsync,
		.vsync,
		.de
	);

	// bitmap: big-endian vector, so we can write pixels left to right
	/* verilator lint_off LITENDIAN */
	logic [0:19] bmap [15];  // 20 pixels by 15 lines
	/* verilator lint_on LITENDIAN */

	initial begin
		bmap[0]  = 20'b1010_1110_1000_1000_0110;
		bmap[1]  = 20'b1010_1000_1000_1000_1010;
		bmap[2]  = 20'b1110_1100_1000_1000_1010;
		bmap[3]  = 20'b1010_1000_1000_1000_1010;
		bmap[4]  = 20'b1010_1110_1110_1110_1100;
		bmap[5]  = 20'b0000_0000_0000_0000_0000;
		bmap[6]  = 20'b1010_0110_1110_1000_1100;
		bmap[7]  = 20'b1010_1010_1010_1000_1010;
		bmap[8]  = 20'b1010_1010_1100_1000_1010;
		bmap[9]  = 20'b1110_1010_1010_1000_1010;
		bmap[10] = 20'b1110_1100_1010_1110_1110;
		bmap[11] = 20'b0000_0000_0000_0000_0000;
		bmap[12] = 20'b0000_0000_0000_0000_0000;
		bmap[13] = 20'b0000_0000_0000_0000_0000;
		bmap[14] = 20'b0000_0000_0000_0000_0000;
	end

	// paint at 16x scale in active screen area
	logic picture;
	logic [5:0] x;  // 20 columns need five bits
	logic [4:0] y;  // 15 rows need four bits
	always_comb begin
		x = sx[9:4];  // every 32 horizontal pixels
		y = sy[8:4];  // every 32 vertical pixels
		picture = 0;
		if (de) 
			if (x < 20 && y < 15)
				picture = bmap[y][x];  // look up pixel (unless we're in blanking)
	end

	// paint colours: yellow lines, blue background
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		paint_r = (picture) ? 5'hF << 1: 5'h1 << 1;
		paint_g = (picture) ? 6'hC << 2: 6'h3 << 2;
		paint_b = (picture) ? 5'h0 << 1: 5'h7 << 1;
	end

	// VGA Pmod output
	assign vga_clk = clk_pix;

	always_ff @(posedge clk_pix) begin
		vga_hsync <= hsync;
		vga_vsync <= vsync;
		vga_de <= de;
		if (de) begin
			vga_r <= paint_r;
			vga_g <= paint_g;
			vga_b <= paint_b;
		end else begin  // VGA colour should be black in blanking interval
			vga_r <= 0;
			vga_g <= 0;
			vga_b <= 0;
		end
	end

endmodule
