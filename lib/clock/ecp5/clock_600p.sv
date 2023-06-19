// Project F Library - 800x600p60 Clock Generation (ECP5)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Generates 40 MHz (800x600 60 Hz) with 25 MHz input clock

// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters

module clock_600p (
	input  wire logic clk_25m,		// input clock (25 MHz)
	input  wire logic rst,			// reset
	output logic clk_pix,			// pixel clock
    output logic clk_pix_10x,		// 10x clock for 10:1 DDR SerDes
	output	logic clk_pix_locked	// pixel clock locked?
);

logic locked;

(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="400" *)
(* FREQUENCY_PIN_CLKOS="40" *)
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
	.CLKI_DIV(1),
	.CLKOP_ENABLE("ENABLED"),
	.CLKOP_DIV(1),
	.CLKOP_CPHASE(0),
	.CLKOP_FPHASE(0),
	.CLKOS_ENABLE("ENABLED"),
	.CLKOS_DIV(10),
	.CLKOS_CPHASE(0),
	.CLKOS_FPHASE(0),
	.FEEDBK_PATH("CLKOP"),
	.CLKFB_DIV(16)
) pll_i (
	.RST(rst),
	.STDBY(1'b0),
	.CLKI(clk_25m),
	.CLKOP(clk_pix_10x),
	.CLKOS(clk_pix),
	.CLKFB(clk_pix_10x),
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
