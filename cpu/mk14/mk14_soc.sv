// MK14 cpu SoC

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module mk14_soc #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter INIT_F = ""
)
(
	input wire logic rst_n,
	input wire logic clk,
	output logic [7:0] trace,
	output logic [8 * 8 - 1:0] display
);

logic [7:0] data_in;
logic [7:0] data_out;

logic core_en = 0;
logic [15:0] core_addr;
logic [15:0] display_addr;
logic core_write_en;
logic display_write_en;

bram_sdp #(.WIDTH(8), .DEPTH(4096), .INIT_F(INIT_F))
program_inst (
	.clk_write(clk), .clk_read(clk),
	.we(core_en & core_write_en),
	.addr_write(core_en ? core_addr : display_addr),
	.addr_read(core_en ? core_addr : display_addr),
	.data_in, .data_out
);

core #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ)
) core_inst (
	.rst_n(rst_n),
	.clk,
	.en(core_en),
	.mem_addr(core_addr),
	.mem_read_data(data_out),
	.mem_write_en(core_write_en),
	.mem_write_data(data_in)
);

enum {s_RESET
} state, next_state;

logic [2:0] display_counter = 0;

always @(posedge clk) begin
	if (!core_en) begin
		display_addr <= 16'h0d00 + display_counter;
		display[8 * display_counter + 7 -: 8] <= data_out;
		display_counter <= display_counter + 1;
	end
end

always @(posedge clk) begin
	if (!rst_n) begin
		state <= s_RESET;
	end
	else begin
		case (state)
		s_RESET: begin
			core_en <= 1;
		end
		
		default:
			state <= s_RESET;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
