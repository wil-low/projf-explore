`default_nettype none
`timescale 1ns / 1ps

module vdu_hdmi_480p #(
	parameter FONT_F = "",
	parameter BASE_ADDR = 0
)
(
	input wire clk_pix,
	input wire clk_pix_tmds,
	input wire logic rst_pix,

	output logic read_en,			// read memory enable
	output logic [15:0] read_addr,	// read address
	input  wire [7:0] display_data,	// display memory data

	output logic [3:0] hdmi_p,
	output logic [3:0] hdmi_n
);

// screen dimensions (must match display_inst)
localparam H_RES = 640;
localparam V_RES = 480;

localparam SCALE = 1;

// display sync signals and coordinates
localparam CORDW = 16;  // signed coordinate width (bits)
logic signed [CORDW-1:0] sx, sy;
logic hsync, vsync;
logic de, line, frame;
display_480p #(.CORDW(CORDW)) display_inst (
	.clk_pix(clk_pix),
	.rst_pix(rst_pix),
	.sx,
	.sy,
	.hsync,
	.vsync,
	.de,
	.frame,
	.line
);

// VDU
logic drawing;  // drawing at (sx,sy)

vdu #(
	.BASE_ADDR(BASE_ADDR),
	.H_RES(H_RES),
	.SCALE(SCALE),
	.FONT_F(FONT_F),
	.X_OFFSET((H_RES - ((16 * 8) << SCALE)) / 2),
	.Y_OFFSET((V_RES - ((32 * 8) << SCALE)) / 2)
)
vdu_inst (
	.i_clk(clk_pix),
	.i_en(1),
	.i_frame(frame),
	.i_line(line),
	.i_sx(sx),
	.i_sy(sy),
	.o_read_en(read_en),
	.o_read_addr(read_addr),
	.i_display_data(display_data),
	.o_drawing(drawing)
);

// paint colours: yellow sprite, blue background
logic [7:0] paint_r, paint_b, paint_g;
always_comb begin
	paint_r = drawing ? (8'hF << 1) : (8'h1 << 1);
	paint_g = drawing ? (8'hC << 1) : (8'h3 << 1);
	paint_b = drawing ? (8'h0 << 1) : (8'h7 << 1);
end

// Convert the 8-bit colours into 10-bit TMDS values
logic [9:0] TMDS_red, TMDS_grn, TMDS_blu;
TMDS_encoder encode_R (
	.clk(clk_pix),
	.VD(paint_r),
	.CD(2'b00),
	.VDE(de),
	.TMDS(TMDS_red)
);
TMDS_encoder encode_G (
	.clk(clk_pix),
	.VD(paint_g),
	.CD(2'b00),
	.VDE(de),
	.TMDS(TMDS_grn)
);
TMDS_encoder encode_B (
	.clk(clk_pix),
	.VD(paint_b),
	.CD({vsync, hsync}),
	.VDE(de),
	.TMDS(TMDS_blu)
);

// Strobe the TMDS_shift_load once every 10 clk_pix_tmds
// i.e. at the start of new pixel data
logic [3:0] TMDS_mod10 = 0;
logic TMDS_shift_load = 0;
always @(posedge clk_pix_tmds) begin
	if (rst_pix) begin
		TMDS_mod10 <= 0;
		TMDS_shift_load <= 0;
	end
	else begin
		TMDS_mod10 <= (TMDS_mod10 == 4'd9) ? 4'd0 : TMDS_mod10 + 4'd1;
		TMDS_shift_load <= (TMDS_mod10 == 4'd9);
	end
end

// Latch the TMDS colour values into three shift registers
// at the start of the pixel, then shift them one bit each clk_pix_tmds.
// We will then output the LSB on each clk_pix_tmds.
logic [9:0] TMDS_shift_red=0, TMDS_shift_grn=0, TMDS_shift_blu=0;
always @(posedge clk_pix_tmds) begin
	if (rst_pix) begin
		TMDS_shift_red <= 0;
		TMDS_shift_grn <= 0;
		TMDS_shift_blu <= 0;
	end
	else begin
		TMDS_shift_red <= TMDS_shift_load ? TMDS_red: {1'b0, TMDS_shift_red[9:1]};
		TMDS_shift_grn <= TMDS_shift_load ? TMDS_grn: {1'b0, TMDS_shift_grn[9:1]};
		TMDS_shift_blu <= TMDS_shift_load ? TMDS_blu: {1'b0, TMDS_shift_blu[9:1]};
	end
end

// Finally output the LSB of each color bitstream

OBUFDS OBUFDS_red(
	.I(TMDS_shift_red[0]),
	.O(hdmi_p[2]),
	.OB(hdmi_n[2])
);
OBUFDS OBUFDS_grn(
	.I(TMDS_shift_grn[0]),
	.O(hdmi_p[1]),
	.OB(hdmi_n[1])
);
OBUFDS OBUFDS_blu(
	.I(TMDS_shift_blu[0]),
	.O(hdmi_p[0]),
	.OB(hdmi_n[0])
);
OBUFDS OBUFDS_clock(
	.I(clk_pix),
	.O(hdmi_p[3]),
	.OB(hdmi_n[3])
);

endmodule
