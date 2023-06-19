// Project F Library - 480x272p60 Clock Generation (ECP5)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Generates 18 MHz (480x272 59.8 Hz) with 25 MHz input clock

// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters

module clock_272p (
	input  wire logic clk_25m,		// input clock (25 MHz)
	input  wire logic rst,			// reset
	output	  logic clk_pix,		// pixel clock
	output	  logic clk_pix_locked // pixel clock locked?
//	output	  logic input_clk_copy  // copy of input clock
);

localparam FEEDBACK_PATH="SIMPLE";
localparam DIVR=4'b0000;
localparam DIVF=7'b0101111;
localparam DIVQ=3'b101;
localparam FILTER_RANGE=3'b001;

logic locked;
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="17.8571" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
	.PLLRST_ENA("ENABLED"),
	.INTFB_WAKE("DISABLED"),
	.STDBY_ENABLE("DISABLED"),
	.DPHASE_SOURCE("DISABLED"),
	.OUTDIVIDER_MUXA("DIVA"),
	.OUTDIVIDER_MUXB("DIVB"),
	.OUTDIVIDER_MUXC("DIVC"),
	.OUTDIVIDER_MUXD("DIVD"),
	.CLKI_DIV(7),
	.CLKOP_ENABLE("ENABLED"),
	.CLKOP_DIV(34),
	.CLKOP_CPHASE(16),
	.CLKOP_FPHASE(0),
	.FEEDBK_PATH("CLKOP"),
	.CLKFB_DIV(5)
) pll_i (
	.RST(rst),
	.STDBY(1'b0),
	.CLKI(clk_25m),
	.CLKOP(clk_pix),
	.CLKFB(clk_pix),
	.CLKINTFB(),
	.PHASESEL0(1'b0),
	.PHASESEL1(1'b0),
	.PHASEDIR(1'b1),
	.PHASESTEP(1'b1),
	.PHASELOADREG(1'b1),
	.PLLWAKESYNC(1'b0),
	.ENCLKOP(1'b0),
	.LOCK(locked)
);

// ensure clock lock is synced with pixel clock
logic locked_sync_0;
always_ff @(posedge clk_pix) begin
	locked_sync_0 <= locked;
	clk_pix_locked <= locked_sync_0;
end

endmodule
