// Project F: Framebuffers - Mono David (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/framebuffers/

`default_nettype none
`timescale 1ns / 1ps

module top_david_mono (
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

	// reset in pixel clock domain
	logic rst_pix;
	always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

	// display sync signals and coordinates
	localparam CORDW = 16;  // signed coordinate width (bits)
	logic signed [CORDW-1:0] sx, sy;
	logic hsync, vsync;
	logic de, frame;
	display_272p #(.CORDW(CORDW)) display_inst (
		.clk_pix,
		.rst_pix,
		.sx,
		.sy,
		.hsync,
		.vsync,
		.de,
		.frame,
		/* verilator lint_off PINCONNECTEMPTY */
		.line()
		/* verilator lint_on PINCONNECTEMPTY */
	);

	// colour parameters
	localparam CHANW = 4;  // colour channel width (bits)

	// framebuffer (FB)
	localparam FB_WIDTH  = 160;  // framebuffer width in pixels
	localparam FB_HEIGHT = 120;  // framebuffer width in pixels
	localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
	localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
	localparam FB_DATAW  = 1;  // colour bits per pixel
	//localparam FB_IMAGE  = "../res/david/david_1bit.mem";  // bitmap file
	localparam FB_IMAGE  = "../../../lib/res/test/test_box_mono_160x120.mem";  // bitmap file

	// pixel read address and colour
	logic [FB_ADDRW-1:0] fb_addr_read;
	logic [FB_DATAW-1:0] fb_colr_read;

	// framebuffer memory
	bram_sdp #(
		.WIDTH(FB_DATAW),
		.DEPTH(FB_PIXELS),
		.INIT_F(FB_IMAGE)
	) bram_inst (
		.clk_write(clk_pix),
		.clk_read(clk_pix),
		/* verilator lint_off PINCONNECTEMPTY */
		.we(),
		.addr_write(),
		/* verilator lint_on PINCONNECTEMPTY */
		.addr_read(fb_addr_read),
		/* verilator lint_off PINCONNECTEMPTY */
		.data_in(),
		/* verilator lint_on PINCONNECTEMPTY */
		.data_out(fb_colr_read)
	);

	// calculate framebuffer read address for display output
	localparam LAT = 2;  // read_fb+1, BRAM+1
	logic read_fb;
	always_ff @(posedge clk_pix) begin
		read_fb <= (sy >= 0 && sy < FB_HEIGHT && sx >= -LAT && sx < FB_WIDTH-LAT);
		if (frame) begin  // reset address at start of frame
			fb_addr_read <= 0;
		end else if (read_fb) begin  // increment address in painting area
			fb_addr_read <= fb_addr_read + 1;
		end
	end

	// paint screen
	logic paint_area;  // area of framebuffer to paint
	logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
	always_comb begin
		paint_area = (sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx < FB_WIDTH);
		{paint_r, paint_g, paint_b} = (paint_area && fb_colr_read) ? 12'hFFF: 12'h000;
	end

	// VGA Pmod output
	assign vga_clk = clk_pix;

	always_ff @(posedge clk_pix) begin
		vga_hsync <= hsync;
		vga_vsync <= vsync;
		vga_de <= de;
		if (de) begin
			vga_r <= paint_r << 1;
			vga_g <= paint_g << 2;
			vga_b <= paint_b << 1;
		end else begin  // VGA colour should be black in blanking interval
			vga_r <= 0;
			vga_g <= 0;
			vga_b <= 0;
		end
	end

endmodule
