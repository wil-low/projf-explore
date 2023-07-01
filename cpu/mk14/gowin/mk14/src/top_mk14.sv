`default_nettype none
`timescale 1ns / 1ps

module top_mk14
(
	input wire logic CLK,
	input wire logic rst_n,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4,

	output logic PROBE,

	output logic LK_CLK,
	output logic LK_STB,
	inout  wire  LK_DIO,

	input wire IR,
	input wire RX,

	output	  logic vga_clk,	  // VGA pixel clock
	output	  logic vga_hsync,	// VGA horizontal sync
	output	  logic vga_vsync,	// VGA vertical sync
	output	  logic vga_de,	   // VGA data enable
	output	  logic [4:0] vga_r,  // 5-bit VGA red
	output	  logic [5:0] vga_g,  // 6-bit VGA green
	output	  logic [4:0] vga_b   // 5-bit VGA blue
);

logic [7:0] trace;
assign LED = ~trace;

logic rx_wait;
assign {LED2, LED3, LED4} = ~0;
assign LED1 = ~rx_wait;

localparam CLOCK_FREQ_MHZ = 27;

localparam ROM_INIT_F		= "../../programs/SCIOS_Version_2.mem";
//localparam ROM_INIT_F		= "../../programs/display.mem";
localparam STD_RAM_INIT_F	= "../../ext_ram.mem";
localparam EXT_RAM_INIT_F	= "../../ext_ram.mem";

localparam VDU_BASE_ADDR	= 'h0200;
localparam VDU_FONT_F		= "../../vdu/TI-83-portrait.mem";
localparam VDU_RAM_F		= "../../vdu/disp_graph.mem";


// generate pixel clock
logic clk_pix;
logic clk_pix_locked;
logic input_clk_copy;

clock_272p clock_pix_inst (
	.clk_27m(CLK),
	.rst(~rst_n),
	.clk_pix,
	.clk_pix_locked
);

// reset in pixel clock domain
logic rst_pix;
always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

assign input_clk_copy = CLK;

logic vdu_en;				// enable VDU (F1 = ON)
logic vdu_graphics_mode;	// graphics mode (F2 = ON)
logic vdu_read_en;			// read memory enable
logic [15:0] vdu_addr;		// read address
logic [7:0] vdu_data_out;	// display memory data

mk14_soc #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ),
	.ROM_INIT_F(ROM_INIT_F),
	.STD_RAM_INIT_F(STD_RAM_INIT_F),
	.EXT_RAM_INIT_F(EXT_RAM_INIT_F),
	.VDU_RAM_F(VDU_RAM_F),
	.VDU_BASE_ADDR(VDU_BASE_ADDR)
)
mk14_soc_inst (
	.rst_n,
	.clk(input_clk_copy),
	.trace,
	.probe(PROBE),
	.o_ledkey_clk(LK_CLK),
	.o_ledkey_stb(LK_STB),
	.io_ledkey_dio(LK_DIO),
	.ir(IR),
	.sin(),
	.sout(),
	.rx(RX),
	.rx_wait,
	.vdu_en,
	.vdu_graphics_mode,
	.vdu_read_en,
	.vdu_addr,
	.vdu_data_out
);

vdu_vga_272p_portrait #(
	.FONT_F(VDU_FONT_F),
	.BASE_ADDR(VDU_BASE_ADDR)
)
mk14_vdu_inst (
	.clk_pix,
	.rst_pix,
	.en(1'b1/*vdu_en*/),
	.graphics_mode(vdu_graphics_mode),
	.read_en(vdu_read_en),
	.read_addr(vdu_addr),
	.display_data(vdu_data_out),

	.vga_clk,
	.vga_hsync,
	.vga_vsync,
	.vga_de,
	.vga_r,
	.vga_g,
	.vga_b
);

endmodule
