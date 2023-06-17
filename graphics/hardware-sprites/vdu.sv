// Mk14 VDU module

`default_nettype none
`timescale 1ns / 1ps

module vdu #(
	BASE_ADDR = 'h0200,					// start of display memory
	SCALE = 3,							// scaling factor 2^n
	FONT_F = "",						// 8x8 font file (64 chars)
	X_OFFSET = 0,						// X offset on screen
	Y_OFFSET = 0						// Y offset on screen
)
(
	input  wire i_clk,
	input  wire i_en,					// enable VDU
	input  wire i_line,					// start of new line
	input  wire i_sx,					// screen X
	input  wire i_sy,					// screen Y

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

logic [$clog2(FONT_CHAR_COUNT) - 1:0] font_rom_addr;
logic [$clog2(FONT_W) - 1:0] font_rom_data;

rom_async #(
	.WIDTH(FONT_W),
	.DEPTH(FONT_CHAR_COUNT),
	.INIT_F(FONT_F)
)
font_rom(
	.addr(font_rom_addr),
	.data(font_rom_data)
);

/*
always_comb begin
	spr_diff = (sy - spry_r) >>> SPR_SCALE;  // arithmetic right-shift
	spr_active = (spr_diff >= 0) && (spr_diff < SPR_HEIGHT);
	spr_begin = (sx >= sprx_r - SX_OFFS);
	spr_end = (bmap_x == SPR_WIDTH-1);
	line_end = (sx == H_RES - SX_OFFS);
end
*/

logic [$clog2(FONT_W * H_CHARS) - 1:0] counter;

enum {
	s_IDLE, s_FETCH, s_WAIT_MEM, s_READ_FONT, s_FILL_SCANLINE, s_WAIT_POS, s_LINE
} state;

always_ff @(posedge i_clk) begin
	case (state)

	s_IDLE: begin
		o_drawing <= 0;
		if (i_en && i_line) begin
			counter <= 0;
			o_read_addr <= BASE_ADDR;
			state <= s_FETCH;
		end
	end

	s_FETCH: begin
		o_read_en <= 1;
		state <= s_WAIT_MEM;
	end

	s_WAIT_MEM: begin
		state <= s_READ_FONT;
	end

	s_READ_FONT: begin
		font_rom_addr <= i_display_data;
		state <= s_FILL_SCANLINE;
	end

	s_FILL_SCANLINE: begin
		scanline[8 * counter + 7 -: 8] <= font_rom_data;
		counter <= counter + 1;
		state <= (counter == H_CHARS) ? s_WAIT_POS : s_FETCH;
	end

	s_WAIT_POS: begin
		if (i_sx >= X_OFFSET) begin
			state <= s_LINE;
			counter <= 0;
		end
	end

	s_LINE: begin
		o_drawing <= ~o_drawing;
		counter <= counter + 1;
		if (counter == FONT_W * H_CHARS) begin
			state <= s_IDLE;
		end
	end

	default:
		state <= s_IDLE;

	endcase
end

endmodule
