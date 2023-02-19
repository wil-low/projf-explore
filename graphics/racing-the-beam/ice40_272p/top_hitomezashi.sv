// Project F: Racing the Beam - Hitomezashi (iCESugar 16-bit RGBLCD Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hitomezashi (
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

	// stitch start values: big-endian vector, so we can write left to right
	/* verilator lint_off LITENDIAN */
	logic [0:29] v_start;  // 30 vertical lines
	logic [0:16] h_start;  // 17 horizontal lines

	logic [0:29] v_start_tmp;  // 30 vertical lines
	logic [0:16] h_start_tmp;  // 17 horizontal lines

	/* verilator lint_on LITENDIAN */

	initial begin  // random start values
		v_start_tmp = 30'b01100_00101_00110_10011_10101_10101;
		h_start_tmp = 17'b10111_01001_00001_10;
	end

	// screen dimensions (must match display_inst)
	localparam V_RES_FULL = 286;  // vertical screen resolution (including blanking)
	localparam H_RES	  = 480;  // horizontal screen resolution

	logic [5:0] counter = 1;
	always_ff @(posedge clk_pix) begin
		if (sx == H_RES) begin  // on each screen line at the start of blanking
			if (sy == V_RES_FULL - 15) begin  // reset colour on last line of screen
				counter <= counter + 1;
				v_start_tmp <= {v_start_tmp[1:29], 1'b0} ^ (v_start_tmp[0] ? 30'b10000_00000_00000_00000_00001_01001 : 30'b0);
				h_start_tmp <= {v_start_tmp[1:16], 1'b0} ^ (h_start_tmp[0] ? 17'b10010_00000_00000_00 : 17'b0);
				if (counter == 0 && !de) begin
					v_start <= v_start_tmp;
					h_start <= h_start_tmp;
				end
			end
		end
	end

	// paint stitch pattern with 16x16 pixel grid
	logic stitch;
	logic v_line, v_on;
	logic h_line, h_on;
	always_comb begin
		v_line = (sx[3:0] == 4'b0000);
		h_line = (sy[3:0] == 4'b0000);
		v_on = sy[4] ^ v_start[sx[9:4]];
		h_on = sx[4] ^ h_start[sy[8:4]];
		stitch = (v_line && v_on) || (h_line && h_on);
	end

	// paint colours: yellow lines, blue background
	logic [4:0] paint_r, paint_b;
	logic [5:0] paint_g;
	always_comb begin
		paint_r = (stitch) ? 5'hF << 1: 5'h1 << 1;
		paint_g = (stitch) ? 6'hC << 2: 6'h3 << 2;
		paint_b = (stitch) ? 5'h0 << 1: 5'h7 << 1;
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
