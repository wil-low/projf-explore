// Project F: FPGA Graphics - Flag of Ethiopia (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_flag_ethiopia (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    clock_480p clock_pix_inst (
       .clk_12m,
       .rst(btn_rst),
       .clk_pix,
       .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sy;
    logic hsync, vsync, de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        /* verilator lint_on PINCONNECTEMPTY */
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // traditional flag of Ethiopia
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        if (sy < 160) begin  // top of flag is green
            paint_r = 4'h0;
            paint_g = 4'h9;
            paint_b = 4'h3;
        end else if (sy < 320) begin  // middle of flag is yellow
            paint_r = 4'hF;
            paint_g = 4'hE;
            paint_b = 4'h1;
        end else begin  // bottom of flag is red
            paint_r = 4'hE;
            paint_g = 4'h1;
            paint_b = 4'h2;
        end
    end

    // DVI Pmod output
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, paint_r, paint_g, paint_b}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // DVI Pmod clock output: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );
endmodule
