// Project F: Racing the Beam - Colour Cycle (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_colour_cycle (
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
	localparam V_RES = 272;  // vertical screen resolution

	logic frame;  // high for one clock tick at the start of vertical blanking
	always_comb frame = (sy == V_RES && sx == 0);

	// update the colour level every N frames
	localparam FRAME_NUM = 30;  // frames between colour level change
	logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
	logic [3:0] colr_level;  // level of colour being cycled

	always_ff @(posedge clk_pix) begin
		if (frame) begin
			if (cnt_frame == FRAME_NUM-1) begin  // every FRAME_NUM frames
				cnt_frame <= 0;
				colr_level <= colr_level + 1;
			end else cnt_frame <= cnt_frame + 1;
		end
	end

	// determine colour from screen position
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		paint_r = sx[7:4] << 1;  // 16 horizontal pixels of each red level
		paint_g = sy[7:4] << 2;  // 16 vertical pixels of each green level
		paint_b = colr_level << 1;  // blue level changes over time
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
