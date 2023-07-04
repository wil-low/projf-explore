`default_nettype none
`timescale 1ns / 1ps

module vdu_hdmi_720p #(
	parameter FONT_F = "",
	parameter BASE_ADDR = 0
)
(
	input wire logic clk_pix,
	input wire logic clk_pix_5x,
	input wire logic clk_pix_locked,
	input wire logic rst_pix,

	input wire logic en,
	input wire logic graphics_mode,

	output logic read_en,			// read memory enable
	output logic [15:0] read_addr,	// read address
	input  wire [7:0] display_data,	// display memory data

	output logic [3:0] hdmi_p,
	output logic [3:0] hdmi_n
);

// screen dimensions (must match display_inst)
localparam H_RES = 1280;
localparam V_RES = 720;

localparam C_SCALE = 1;
localparam G_SCALE = 3;

// display sync signals and coordinates
localparam CORDW = 16;  // signed coordinate width (bits)
logic signed [CORDW-1:0] sx, sy;
logic hsync, vsync;
logic de, line, frame;

logic read_enabled;
assign read_en = read_enabled && en;

display_720p #(
	.CORDW(CORDW)
)
display_inst (
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
	.C_SCALE(C_SCALE),
	.G_SCALE(G_SCALE),
	.FONT_F(FONT_F)
)
vdu_inst (
	.i_clk(clk_pix),
	.i_en(1),
	.i_frame(frame),
	.i_line(line),
	.i_x_offset(graphics_mode ? (H_RES - (64 << G_SCALE)) / 2 : (H_RES - ((16 * 8) << C_SCALE)) / 2),
	.i_y_offset(graphics_mode ? (V_RES - (64 << G_SCALE)) / 2 : (V_RES - ((32 * 8) << C_SCALE)) / 2),
	.i_sx(sx),
	.i_sy(sy),
	.o_read_en(read_en),
	.o_read_addr(read_addr),
	.i_display_data(display_data),
	.o_drawing(drawing)
);

// paint colours: yellow sprite, blue background

// DVI signals
logic [7:0] dvi_red, dvi_green, dvi_blue;
logic dvi_hsync, dvi_vsync, dvi_de;
always_ff @(posedge clk_pix) begin
	dvi_hsync <= hsync;
	dvi_vsync <= vsync;
	dvi_de    <= de;
	if (en) begin
		dvi_red = drawing ?		8'hff : 8'h00;
		dvi_green = drawing ?	8'hd7 : 8'h57;
		dvi_blue = drawing ?	8'h00 : 8'hb8;
	end
	else begin
		dvi_red = 0;
		dvi_green = 0;
		dvi_blue = 0;
	end
end

// TMDS encoding and serialization
logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
dvi_generator dvi_out (
	.clk_pix,
	.clk_pix_5x,
	.rst_pix(!clk_pix_locked),
	.de(dvi_de),
	.data_in_ch0(dvi_blue),
	.data_in_ch1(dvi_green),
	.data_in_ch2(dvi_red),
	.ctrl_in_ch0({dvi_vsync, dvi_hsync}),
	.ctrl_in_ch1(2'b00),
	.ctrl_in_ch2(2'b00),
	.tmds_ch0_serial,
	.tmds_ch1_serial,
	.tmds_ch2_serial,
	.tmds_clk_serial
);

// TMDS output pins
tmds_out tmds_ch0 (.tmds(tmds_ch0_serial),
	.pin_p(hdmi_p[0]), .pin_n(hdmi_n[0]));

tmds_out tmds_ch1 (.tmds(tmds_ch1_serial),
	.pin_p(hdmi_p[1]), .pin_n(hdmi_n[1]));

tmds_out tmds_ch2 (.tmds(tmds_ch2_serial),
	.pin_p(hdmi_p[2]), .pin_n(hdmi_n[2]));

tmds_out tmds_clk (.tmds(tmds_clk_serial),
	.pin_p(hdmi_p[3]), .pin_n(hdmi_n[3]));

endmodule
