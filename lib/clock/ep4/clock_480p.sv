// Project F Library - 640x480p60 Clock Generation (XC7)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Generates 25.2 MHz (640x480 60 Hz) with 50 MHz input clock
// ALTPLL

module clock_480p (
    input  wire logic clk_50m,       // input clock (50 MHz)
    input  wire logic rst,            // reset
    output      logic clk_pix,        // pixel clock
    output      logic clk_pix_locked  // pixel clock locked?
    );

    logic locked;            // unsynced lock signal

    pll_25m pll_25m_inst (
        .areset(rst),
        .inclk0(clk_50m),
        .c0(clk_pix),
        .locked(locked)
    );

    // ensure clock lock is synced with pixel clock
    logic locked_sync_0;
    always_ff @(posedge clk_pix) begin
        locked_sync_0 <= locked;
        clk_pix_locked <= locked_sync_0;
    end
endmodule
