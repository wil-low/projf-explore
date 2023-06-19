`default_nettype none
`timescale 1ns / 1ps

module vdu_vga_600p #(
	parameter FONT_F = "",
	parameter BASE_ADDR = 0
)
(
	input wire clk_pix,
	input wire logic rst_pix,

	output logic read_en,			// read memory enable
	output logic [15:0] read_addr,	// read address
	input  wire [7:0] display_data,	// display memory data

	output logic vga_clk,	  // VGA pixel clock
	output logic vga_hsync,	// VGA horizontal sync
	output logic vga_vsync,	// VGA vertical sync
	output logic vga_de,	   // VGA data enable
	output logic [4:0] vga_r,  // 5-bit VGA red
	output logic [5:0] vga_g,  // 6-bit VGA green
	output logic [4:0] vga_b   // 5-bit VGA blue
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
logic [4:0] paint_r, paint_b;
logic [5:0] paint_g;
always_comb begin
	paint_r = drawing ? (5'hF << 1) : (5'h1 << 1);
	paint_g = drawing ? (6'hC << 2) : (6'h3 << 1);
	paint_b = drawing ? (5'h0 << 1) : (5'h7 << 1);
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
