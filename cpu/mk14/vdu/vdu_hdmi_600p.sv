`default_nettype none
`timescale 1ns / 1ps

module vdu_hdmi_600p #(
	parameter FONT_F = "",
	parameter BASE_ADDR = 0
)
(
	input wire clk_pix,
	input wire clk_pix_5x,
	input wire logic rst_pix,

	output logic read_en,			// read memory enable
	output logic [15:0] read_addr,	// read address
	input  wire [7:0] display_data,	// display memory data

	output logic [3:0] hdmi_p,
	output logic [3:0] hdmi_n
);

// screen dimensions (must match display_inst)
localparam H_RES = 800;
localparam V_RES = 600;

localparam SCALE = 1;

// display sync signals and coordinates
localparam CORDW = 16;  // signed coordinate width (bits)
logic signed [CORDW-1:0] sx, sy;
logic hsync, vsync;
logic de, line, frame;
display_600p #(.CORDW(CORDW)) display_inst (
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

// DVI signals (8 bits per colour channel)
logic [7:0] dvi_r, dvi_g, dvi_b;
logic dvi_hsync, dvi_vsync, dvi_de;
always_ff @(posedge clk_pix) begin
	dvi_hsync <= hsync;
	dvi_vsync <= vsync;
	dvi_de    <= de;
	dvi_r     <= paint_r;
	dvi_g     <= paint_g;
	dvi_b     <= paint_b;
end

// TMDS encoding and serialization
logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
dvi_generator dvi_out (
	.clk_pix,
	.clk_pix_5x,
	.rst_pix,
	.de(dvi_de),
	.data_in_ch0(dvi_b),
	.data_in_ch1(dvi_g),
	.data_in_ch2(dvi_r),
	.ctrl_in_ch0({dvi_vsync, dvi_hsync}),
	.ctrl_in_ch1(2'b00),
	.ctrl_in_ch2(2'b00),
	.tmds_ch0_serial,
	.tmds_ch1_serial,
	.tmds_ch2_serial,
	.tmds_clk_serial
);

// TMDS output pins
tmds_out tmds_ch0 (
	.tmds(tmds_ch0_serial),
	.pin_p(hdmi_p[0]),
	.pin_n(hdmi_n[0])
);
tmds_out tmds_ch1 (
	.tmds(tmds_ch1_serial),
	.pin_p(hdmi_p[1]),
	.pin_n(hdmi_n[1])
);
tmds_out tmds_ch2 (
	.tmds(tmds_ch2_serial),
	.pin_p(hdmi_p[2]),
	.pin_n(hdmi_n[2])
);
tmds_out tmds_clk (
	.tmds(tmds_clk_serial),
	.pin_p(hdmi_p[3]),
	.pin_n(hdmi_n[3])
);

endmodule
