// Project F: Hardware Sprites - Tiny F with Scaling (Tang Nano 9k 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_vdu_test (
	input  wire logic clk_27m,	  // 27 MHz clock
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
	   .clk_27m,
	   .rst(~btn_rst),
	   .clk_pix,
	   .clk_pix_locked
	);

	// reset in pixel clock domain
	logic rst_pix;
	always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

	// display sync signals and coordinates
	localparam CORDW = 16;  // signed coordinate width (bits)
	logic signed [CORDW-1:0] sx, sy;
	logic hsync, vsync;
	logic de, line, frame;
	display_272p #(.CORDW(CORDW)) display_inst (
		.clk_pix,
		.rst_pix,
		.sx,
		.sy,
		.hsync,
		.vsync,
		.de,
		.frame,
		.line
	);

	// screen dimensions (must match display_inst)
	localparam H_RES = 480;
	localparam V_RES = 272;
 
	// sprite parameters
	localparam SPR_WIDTH  =  8;  // bitmap width in pixels
	localparam SPR_HEIGHT =  8;  // bitmap height in pixels
	localparam SPR_SCALE  =  3;  // 2^3 = 8x scale
	localparam SPR_DATAW  =  1;  // bits per pixel
	localparam SPR_FILE = "../../res/sprites/TI-83.mem";  // bitmap file

	logic signed [CORDW-1:0] sprx = 0;  // horizontal position
	logic signed [CORDW-1:0] spry = 0;  // vertical position

	// sprite
	logic drawing;  // drawing at (sx,sy)
	logic [SPR_DATAW-1:0] pix;  // pixel colour index
	sprite #(
		.CORDW(CORDW),
		.H_RES(H_RES),
		.SPR_FILE(SPR_FILE),
		.SPR_WIDTH(SPR_WIDTH),
		.SPR_HEIGHT(SPR_HEIGHT),
		.SPR_SCALE(SPR_SCALE),
		.SPR_DATAW(SPR_DATAW)
		) sprite_f (
		.clk(clk_pix),
		.rst(rst_pix),
		.line,
		.sx,
		.sy,
		.sprx,
		.spry,
		.pix,
		.drawing
	);

	// paint colours: yellow sprite, blue background
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		paint_r = (drawing && pix) ? (5'hF << 1) : (5'h1 << 1);
		paint_g = (drawing && pix) ? (6'hC << 2) : (6'h3 << 1);
		paint_b = (drawing && pix) ? (5'h0 << 1) : (5'h7 << 1);
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
		if (frame) begin
			if (sprx < H_RES) begin
				sprx <=  sprx + (SPR_WIDTH << SPR_SCALE);
			end
			else begin
				sprx <= 0;
				if (spry < V_RES)
					spry <= spry + (SPR_HEIGHT << SPR_SCALE);
				else
					spry <= 0;
			end
		end
	end
endmodule
