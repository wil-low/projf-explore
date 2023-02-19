// Project F: FPGA Graphics - Flag of Ethiopia (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_flag_ethiopia (
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
	logic [CORDW-1:0] sy;
	logic hsync, vsync, de;
	simple_272p display_inst (
		.clk_pix,
		.rst_pix(!clk_pix_locked),  // wait for clock lock
		/* verilator lint_off PINCONNECTEMPTY */
		.sx(),
		/* verilator lint_on PINCONNECTEMPTY */
		.sy,
		.hsync,
		.vsync,
		.de
	);

	// traditional flag of Ethiopia
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		if (sy < 91) begin  // top of flag is green
			paint_r = 'h0 << 1;
			paint_g = 'h9 << 2;
			paint_b = 'h3 << 1;
		end else if (sy < 180) begin  // middle of flag is yellow
			paint_r = 'hF << 1;
			paint_g = 'hE << 2;
			paint_b = 'h1 << 1;
		end else begin  // bottom of flag is red
			paint_r = 'hE << 1;
			paint_g = 'h1 << 2;
			paint_b = 'h2 << 1;
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
