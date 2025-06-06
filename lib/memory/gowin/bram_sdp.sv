// Project F Library - Simple Dual-Port Block RAM
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module bram_sdp #(
    parameter WIDTH = 8, 
    parameter DEPTH = 256, 
    parameter INIT_F = ""
    ) (
    input wire logic clk_write,               // write clock (port a)
    input wire logic clk_read,                // read clock (port b)
    input wire logic we,                      // write enable (port a)
    input wire logic [$clog2(DEPTH)-1:0] addr_write,  // write address (port a)
    input wire logic [$clog2(DEPTH)-1:0] addr_read,   // read address (port b)
    input wire logic [WIDTH-1:0] data_in,     // data in (port a)
    output     logic [WIDTH-1:0] data_out     // data out (port b)
    );

    (* ramstyle="no_rw_check" *) logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Loading memory init file '%s' into bram_sdp.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    // Port A: Sync Write
    always_ff @(posedge clk_write) begin
        if (we) memory[addr_write] <= data_in;
    end

    // Port B: Sync Read
    always_ff @(posedge clk_read) begin
        if (we && addr_write == addr_read)
            data_out <= data_in;  // Bypass write data for same address
        else
            data_out <= memory[addr_read];
    end
endmodule
