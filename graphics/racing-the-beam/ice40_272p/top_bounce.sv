// Project F: Racing the Beam - Bounce (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_bounce (
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
	localparam H_RES = 480;  // horizontal screen resolution
	localparam V_RES = 272;  // vertical screen resolution

	logic frame;  // high for one clock tick at the start of vertical blanking
	always_comb frame = (sy == V_RES && sx == 0);

	// frame counter lets us to slow down the action
	localparam FRAME_NUM = 1;  // slow-mo: animate every N frames
	logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
	always_ff @(posedge clk_pix) begin
		if (frame) cnt_frame <= (cnt_frame == FRAME_NUM-1) ? 0 : cnt_frame + 1;
	end

	// square parameters
	localparam Q_SIZE = 60;   // size in pixels
	logic [CORDW-1:0] qx, qy;  // position (origin at top left)
	logic qdx, qdy;			// direction: 0 is right/down
	logic [CORDW-1:0] qs = 9;  // speed in pixels/frame

	// update square position once per frame
	always_ff @(posedge clk_pix) begin
		if (frame && cnt_frame == 0) begin
			// horizontal position
			if (qdx == 0) begin  // moving right
				if (qx + Q_SIZE + qs >= H_RES-1) begin  // hitting right of screen?
					qx <= H_RES - Q_SIZE - 1;  // move right as far as we can
					qdx <= 1;  // move left next frame
				end else qx <= qx + qs;  // continue moving right
			end else begin  // moving left
				if (qx < qs) begin  // hitting left of screen?
					qx <= 0;  // move left as far as we can
					qdx <= 0;  // move right next frame
				end else qx <= qx - qs;  // continue moving left
			end

			// vertical position
			if (qdy == 0) begin  // moving down
				if (qy + Q_SIZE + qs >= V_RES-1) begin  // hitting bottom of screen?
					qy <= V_RES - Q_SIZE - 1;  // move down as far as we can
					qdy <= 1;  // move up next frame
				end else qy <= qy + qs;  // continue moving down
			end else begin  // moving up
				if (qy < qs) begin  // hitting top of screen?
					qy <= 0;  // move up as far as we can
					qdy <= 0;  // move down next frame
				end else qy <= qy - qs;  // continue moving up
			end
		end
	end

	// define a square with screen coordinates
	logic square;
	always_comb begin
		square = (sx >= qx) && (sx < qx + Q_SIZE) && (sy >= qy) && (sy < qy + Q_SIZE);
	end

	// paint colours: white inside square, blue outside
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		paint_r = (square) ? 5'hF << 1 : 5'h1 << 1;
		paint_g = (square) ? 6'hF << 2 : 6'h3 << 2;
		paint_b = (square) ? 5'hF << 1 : 5'h7 << 1;
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
