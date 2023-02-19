// Project F: Racing the Beam - Colour Test (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars (
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

	// screen dimensions (must match display_inst)
	localparam V_RES_FULL = 286;  // vertical screen resolution (including blanking)
	localparam H_RES	  = 480;  // horizontal screen resolution

	localparam START_COLR = {5'h1 << 1, 6'h2 << 2, 5'h6 << 1};  // bar start colour (blue: 12'h126) (gold: 12'h640)
	localparam COLR_NUM   = 10;	   // colours steps in each bar (don't overflow)
	localparam LINE_NUM   =  2;	   // lines of each colour

	logic [15:0] bar_colr;  // 16 bit colour (RGB565)
	logic bar_inc;  // increase (or decrease) brightness
	logic [$clog2(COLR_NUM):0] cnt_colr;  // count colours in each bar
	logic [$clog2(LINE_NUM):0] cnt_line;  // count lines of each colour

	// update colour for each screen line
	always_ff @(posedge clk_pix) begin
		if (sx == H_RES) begin  // on each screen line at the start of blanking
			if (sy == V_RES_FULL-1) begin  // reset colour on last line of screen
				bar_colr <= START_COLR;
				bar_inc <= 1;  // start by increasing brightness
				cnt_colr <= 0;
				cnt_line <= 0;
			end else if (cnt_line == LINE_NUM-1) begin  // colour complete
				cnt_line <= 0;
				if (cnt_colr == COLR_NUM-1) begin  // switch increase/decrease
					bar_inc <= ~bar_inc;
					cnt_colr <= 0;
				end else begin
					bar_colr <= (bar_inc) ? bar_colr + {5'h1, 6'h1, 5'h1} : bar_colr - {5'h1, 6'h1, 5'h1};
					cnt_colr <= cnt_colr + 1;
				end
			end else cnt_line <= cnt_line + 1;
		end
	end

	// separate colour channels
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb {paint_r, paint_g, paint_b} = bar_colr;

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
