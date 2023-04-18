// Project F Library - Simple Dual-Port Block RAM (iCE40)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module bram_read_async #(
    parameter WIDTH = 8, 
    parameter DEPTH = 512, 
    parameter INIT_F = ""
    ) (
    input wire logic clk,
    input wire logic we,
    input wire logic [$clog2(DEPTH)-1:0] addr_write,
    input wire logic [$clog2(DEPTH)-1:0] addr_read,
    input wire logic [WIDTH-1:0] data_in,
    output     logic [WIDTH-1:0] data_out
    );

    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Creating bram from init file '%s'.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    always_ff @(posedge clk) begin
        if (we) memory[addr_write] <= data_in;
    end

    assign data_out = memory[addr_read];

endmodule
