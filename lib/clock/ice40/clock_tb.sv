// Project F Library - Clock Generation Test Bench (ice40)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module clock_tb ();

    parameter CLK_PERIOD = 10;

    logic rst, clk_12m;

    // 480x272p60 clocks
    logic clk_272p;
    logic clk_locked_272p;

    clock_272p clock_272p_inst (
       .clk_12m,
       .rst,
       .clk_pix(clk_272p),
       .clk_pix_locked(clk_locked_272p)
    );

    // 640x480p60 clocks
    logic clk_480p;
    logic clk_locked_480p;

    clock_480p clock_480p_inst (
       .clk_12m,
       .rst,
       .clk_pix(clk_480p),
       .clk_pix_locked(clk_locked_480p)
    );

    always #(CLK_PERIOD / 2) clk_12m = ~clk_12m;

    initial begin
        clk_12m = 1;
        rst = 1;
        #100
        rst = 0;

        #12000
        $finish;
    end

endmodule
