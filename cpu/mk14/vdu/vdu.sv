// Mk14 VDU module

`default_nettype none
`timescale 1ns / 1ps

module vdu #(
    parameter CORDW = 16,      			// signed coordinate width (bits)
	parameter H_RES = 480,     			// horizontal screen resolution (pixels)
	parameter BASE_ADDR = 'h0200,		// start of display memory
	parameter C_SCALE = 3,				// character mode scaling factor 2^n
	parameter G_SCALE = 3,				// graphics mode scaling factor 2^n
	parameter FONT_F = ""				// 8x8 font file (64 chars)
)
(
	input  wire i_clk_sys,				// system clock
	input  wire i_clk_pix,				// pixel clock
	input  wire i_en,					// enable VDU
	input  wire i_graphics_mode,		// 0 - character, 1 - graphics
	input  wire i_frame,				// start of new frame
	input  wire i_line,					// start of new line
	input  wire signed [CORDW - 1:0] i_x_offset, // X offset on screen
	input  wire signed [CORDW - 1:0] i_y_offset, // Y offset on screen
	input  wire signed [CORDW - 1:0] i_sx,	// screen X
	input  wire signed [CORDW - 1:0] i_sy,	// screen Y

	output logic o_read_en,				// read memory enable
	output logic [15:0] o_read_addr,	// read address
	input  wire [7:0] i_display_data,	// display memory data

	output logic o_drawing				// drawing flag
);

localparam H_CHARS = 16;
localparam V_CHARS = 32;

localparam FONT_W = 8;
localparam FONT_H = 8;
localparam FONT_CHAR_COUNT = 64;

logic [FONT_W * H_CHARS - 1:0] scanline;  // current line buffer

logic [$clog2(FONT_H * FONT_CHAR_COUNT) - 1:0] font_rom_addr;
logic [FONT_W - 1:0] font_rom_data;

rom_async #(
	.WIDTH(FONT_W),
	.DEPTH(FONT_H * FONT_CHAR_COUNT),
	.INIT_F(FONT_F),
	.BIN_MODE(1)
)
font_rom(
	.addr(font_rom_addr),
	.data(font_rom_data)
);

logic signed [CORDW - 1:0]  spr_diff;  // diff vertical screen and sprite positions
logic spr_active;  // sprite active on this line
logic [(G_SCALE > C_SCALE ? G_SCALE : C_SCALE):0] cnt_x;	// horizontal scale counter
logic line_end;			// end of screen line, corrected for sx offset

always_comb begin
	if (i_graphics_mode) begin
		spr_diff = (i_sy - i_y_offset) >>> G_SCALE;  // arithmetic right-shift
		spr_active = (spr_diff >= 0) && (spr_diff < 64);
	end
	else begin
		spr_diff = (i_sy - i_y_offset) >>> C_SCALE;  // arithmetic right-shift
		spr_active = (spr_diff >= 0) && (spr_diff < FONT_H * V_CHARS);
	end
	font_rom_addr = i_display_data * FONT_H + spr_diff[2:0];
	line_end = (i_sx == H_RES - i_x_offset);
end

logic [$clog2(FONT_W * H_CHARS) - 1:0] counter;
logic [$clog2(FONT_W * H_CHARS) - 1:0] counter_pix;

typedef enum {
	s_IDLE,
	s_C_PREPARE, s_C_FETCH, s_C_FILL_SCANLINE,
	s_G_PREPARE, s_G_FETCH, s_G_FILL_SCANLINE,
	s_WAIT_POS, s_C_LINE, s_G_LINE, s_WAIT_NEW_LINE
} State;

State state = s_IDLE;
State state_pix = s_IDLE;

// read flags in system clock domain
logic line_sys;
xd xd_line (
	.clk_src(i_clk_pix),
	.clk_dst(i_clk_sys),
	.flag_src(i_line),
	.flag_dst(line_sys)
);
/*
logic lb_en_in, lb_data_in;
logic lb_en_out, lb_data_out;

linebuffer_simple #(
	.DATAW(1),
	.LEN(64)
) linebuffer_instance (
	.clk_sys(i_clk_sys),
	.clk_pix(i_clk_pix),
	.line(i_line),
	.line_sys,
	.en_in(lb_en_in),
	.en_out(lb_en_out),
	.scale(i_graphics_mode ? G_SCALE : C_SCALE),
	.data_in(lb_data_in),
	.data_out(lb_data_out)
);
*/
always_ff @(posedge i_clk_sys) begin

	case (state)

	s_IDLE: begin
		o_read_en <= 0;
		if (i_en && line_sys && spr_active)
			state <= i_graphics_mode ? s_G_PREPARE : s_C_PREPARE;
	end

	// character mode
	s_C_PREPARE: begin
		o_read_en <= 1;
		counter <= H_CHARS - 1;
		o_read_addr <= BASE_ADDR + (spr_diff >> 3) * H_CHARS;
		state <= s_C_FETCH;
	end

	s_C_FETCH: begin
		state <= s_C_FILL_SCANLINE;
	end

	s_C_FILL_SCANLINE: begin
		scanline[8 * counter + 7 -: 8] <= i_display_data[7] ? ~font_rom_data : font_rom_data;
		o_read_addr <= o_read_addr + 1;
		counter <= counter - 1;
		state <= (counter == 0) ? s_IDLE : s_C_FETCH;
	end

	// graphics mode
	s_G_PREPARE: begin
		o_read_en <= 1;
		//scanline <= 0;
		counter <= H_CHARS / 2 - 1;
		o_read_addr <= BASE_ADDR + spr_diff * (H_CHARS / 2);
		state <= s_G_FETCH;
	end

	s_G_FETCH: begin
		state <= s_G_FILL_SCANLINE;
	end

	s_G_FILL_SCANLINE: begin
		scanline[8 * counter + 7 -: 8] <= i_display_data;
		o_read_addr <= o_read_addr + 1;
		counter <= counter - 1;
		state <= (counter == 0) ? s_IDLE : s_G_FETCH;
	end

	endcase
end

always_ff @(posedge i_clk_pix) begin

	case (state_pix)

	s_IDLE: begin
		o_drawing <= 0;
		if (i_en && spr_active && (i_sx >= i_x_offset)) begin
			cnt_x <= 0;
			if (i_graphics_mode) begin
				counter_pix <= 64 - 1;
				state_pix <= s_G_LINE;
			end
			else begin
				counter_pix <= FONT_H * V_CHARS - 1;
				state_pix <= s_C_LINE;
			end
		end
	end

	s_C_LINE: begin
		if (line_end)
			state_pix <= s_WAIT_NEW_LINE;
		o_drawing <= scanline[counter_pix];
		if (C_SCALE == 0 || cnt_x == 2**C_SCALE - 1) begin
			if (counter_pix == 0)
				state_pix <= s_WAIT_NEW_LINE;
			counter_pix <= counter_pix - 1;
			cnt_x <= 0;
		end
		else
			cnt_x <= cnt_x + 1;
	end

	s_G_LINE: begin
		if (line_end)
			state_pix <= s_WAIT_NEW_LINE;
		o_drawing <= scanline[counter_pix];
		if (G_SCALE == 0 || cnt_x == 2**G_SCALE - 1) begin
			if (counter_pix == 0)
				state_pix <= s_WAIT_NEW_LINE;
			counter_pix <= counter_pix - 1;
			cnt_x <= 0;
		end
		else
			cnt_x <= cnt_x + 1;
	end

	s_WAIT_NEW_LINE: begin
		o_drawing <= 0;
		if (i_line)
			state_pix <= s_IDLE;
	end

	default:
		state_pix <= s_IDLE;

	endcase
end

endmodule
