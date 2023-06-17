`default_nettype none
`timescale 1ns / 1ps

module top_vdu (
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

// screen dimensions (must match display_inst)
localparam H_RES = 480;
localparam V_RES = 272;

localparam SCALE = 0;
localparam FONT_F = "../res/sprites/TI-83.mem";
localparam DISP_MEM_F = "../res/sprites/disp_mem.mem";

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
logic de, line, frame;
display_272p #(.CORDW(CORDW)) display_inst (
	.clk_pix,
	.rst_pix,
	.sx,
	.sy,
	.hsync,
	.vsync,
	.de,
	.frame,
	.line
);

bram_sdp #(
	.WIDTH(8), .DEPTH(512), .INIT_F(DISP_MEM_F)
)
disp_mem (
	.clk_write(0),
	.clk_read(clk_pix),
	.we(0),
	.addr_write(),
	.addr_read(read_addr),
	.data_in(),
	.data_out(display_data)
);

// VDU
logic read_en;
logic [15:0] read_addr;
logic [7:0] display_data;
logic drawing;  // drawing at (sx,sy)

vdu #(
	.BASE_ADDR(0),
	.SCALE(SCALE),
	.FONT_F(FONT_F),
	.X_OFFSET((H_RES - ((16 * 8) << SCALE)) / 2),
	.Y_OFFSET(8)
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
