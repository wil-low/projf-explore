// Project F Library - Asynchronous ROM
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module rom_async #(
    parameter WIDTH = 8,
    parameter DEPTH = 256,
    parameter INIT_F = "",
    parameter BIN_MODE = 0
)
(
	input wire logic [$clog2(DEPTH)-1:0] addr,
	output     logic [WIDTH-1:0] data
);

    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Creating rom_async from init file '%s', bin_mode %d", INIT_F, BIN_MODE);
			if (BIN_MODE)
	            $readmemb(INIT_F, memory);
			else
	            $readmemh(INIT_F, memory);
        end
    end

    always_comb data = memory[addr];
endmodule
