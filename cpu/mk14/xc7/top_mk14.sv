`default_nettype none
`timescale 1ns / 1ps

module top_mk14
(
	input wire logic CLK,
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

	output logic [3:0] hdmi_p,	// HDMI ch 0,1,2,clk diff+
	output logic [3:0] hdmi_n	// HDMI ch 0,1,2,clk diff-
);

//// Reset emulation
logic [22:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

logic [7:0] trace;
assign LED = ~trace;

logic rx_wait;
assign LED1 = ~rx_wait;

localparam CLOCK_FREQ_MHZ = 50;

localparam ROM_INIT_F		= "SCIOS_Version_2.mem";
localparam STD_RAM_INIT_F	= "FALLMAN.mem";
//localparam STD_RAM_INIT_F	= "test.mem";
localparam EXT_RAM_INIT_F	= "ext_ram.mem";

localparam VDU_BASE_ADDR	= 'h0200;
localparam VDU_FONT_F		= "TI-83.mem";
localparam VDU_RAM_F		= "disp_graph.mem";

// generate pixel clocks
logic clk_pix;                  // pixel clock
logic clk_pix_5x;               // 5x pixel clock for 10:1 DDR SerDes
logic clk_pix_locked;           // pixel clock locked?
clock_gen_50m_720p clock_pix_inst (
	.clk_50m(CLK),
	.rst(~rst_n),             // reset button is active low
	.clk_pix,
	.clk_pix_5x,
	.clk_pix_locked
);

// reset in pixel clock domain
logic rst_pix;
always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

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
	.clk(CLK),
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

vdu_hdmi_720p #(
	.FONT_F(VDU_FONT_F),
	.BASE_ADDR(VDU_BASE_ADDR)
)
mk14_vdu_inst (
	.clk_sys(CLK),
	.clk_pix,
	.clk_pix_5x,
	.clk_pix_locked,
	.rst_pix,
	.en(1'b1/*vdu_en*/),
	.graphics_mode(vdu_graphics_mode),
	.read_en(vdu_read_en),
	.read_addr(vdu_addr),
	.display_data(vdu_data_out),

	.hdmi_p,
	.hdmi_n
);

endmodule
