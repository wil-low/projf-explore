// Mk14 VDU module

`default_nettype none
`timescale 1ns / 1ps

module vdu #(
    parameter CORDW = 16,      			// signed coordinate width (bits)
	parameter H_RES = 480,     			// horizontal screen resolution (pixels)
	parameter BASE_ADDR = 'h0200,		// start of display memory
	parameter SCALE = 3,				// scaling factor 2^n
	parameter FONT_F = "",				// 8x8 font file (64 chars)
	parameter X_OFFSET = 0,				// X offset on screen
	parameter Y_OFFSET = 0				// Y offset on screen
)
(
	input  wire i_clk,
	input  wire i_en,					// enable VDU
	input  wire i_frame,				// start of new frame
	input  wire i_line,					// start of new line
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
logic [SCALE:0] cnt_x;	// horizontal scale counter
logic line_end;			// end of screen line, corrected for sx offset

always_comb begin
	spr_diff = (i_sy - Y_OFFSET) >>> SCALE;  // arithmetic right-shift
	spr_active = (spr_diff >= 0) && (spr_diff < FONT_H * V_CHARS);
	font_rom_addr = i_display_data * FONT_H + spr_diff[2:0];
	line_end = (i_sx == H_RES - X_OFFSET);
end

logic [$clog2(FONT_W * H_CHARS) - 1:0] counter;

enum {
	s_IDLE, s_FETCH, s_WAIT_MEM, s_FILL_SCANLINE, s_WAIT_POS, s_LINE
} state;

always_ff @(posedge i_clk) begin
	o_read_en <= 0;

	case (state)

	s_IDLE: begin
		o_drawing <= 0;
		if (i_en && i_line && spr_active) begin
			counter <= H_CHARS;
			o_read_addr <= BASE_ADDR + (spr_diff >> 3) * 16;
			state <= s_FETCH;
		end
	end

	s_FETCH: begin
		o_read_en <= 1;
		state <= s_WAIT_MEM;
	end

	s_WAIT_MEM: begin
		state <= s_FILL_SCANLINE;
	end

	s_FILL_SCANLINE: begin
		scanline[8 * counter - 1 -: 8] <= font_rom_data;
		o_read_addr <= o_read_addr + 1;
		counter <= counter - 1;
		state <= (counter == 0) ? s_WAIT_POS : s_FETCH;
	end

	s_WAIT_POS: begin
		if (i_sx >= X_OFFSET) begin
			state <= s_LINE;
			cnt_x <= 0;
			counter <= FONT_W * H_CHARS - 1;
		end
	end

	s_LINE: begin
		if (line_end)
			state <= s_IDLE;
		o_drawing <= scanline[counter];
		if (SCALE == 0 || cnt_x == 2**SCALE - 1) begin
			if (counter == 0)
				state <= s_IDLE;
			counter <= counter - 1;
			cnt_x <= 0;
		end
		else
			cnt_x <= cnt_x + 1;
	end

	default:
		state <= s_IDLE;

	endcase
end

endmodule
