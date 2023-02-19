// Project F: FPGA Graphics - Flag of Sweden (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_flag_sweden (
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
	logic [CORDW-1:0] sx, sy;
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

	// flag of Sweden (16:10 ratio)
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		if (sx >= 435) begin  // black outside the flag area
			paint_r = 'h0;
			paint_g = 'h0;
			paint_b = 'h0;
		end else if (sy > 272 * 4 / 10 && sy < 272 * 6 / 10) begin  // yellow cross horizontal
			paint_r = 'hF << 1;
			paint_g = 'hC << 2;
			paint_b = 'h0 << 1;
		end else if (sx > 435 * 5 / 16 && sx < 435 * 7 / 16) begin  // yellow cross vertical
			paint_r = 'hF << 1;
			paint_g = 'hC << 2;
			paint_b = 'h0 << 1;
		end else begin  // blue flag background
			paint_r = 'h0 << 1;
			paint_g = 'h6 << 2;
			paint_b = 'hA << 1;
		end
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
