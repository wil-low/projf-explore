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
	output logic probe,

	output logic o_ledkey_clk,
	output logic o_ledkey_stb,
	inout  wire  io_ledkey_dio
);

logic [7:0] data_in;
logic [7:0] data_out;

logic core_en = 1;
logic core_write_wait;
logic [15:0] core_addr;
logic [15:0] display_addr;
logic core_write_en;
logic display_write_en;
logic display_idle;

localparam SEG7_COUNT = 8;
localparam SEG7_BASE_ADDR = 'h100;

bram_sdp #(.WIDTH(8), .DEPTH(4096), .INIT_F(INIT_F))
program_inst (
	.clk_write(clk), .clk_read(clk),
	.we(core_en & core_write_en),
	.addr_write(core_en ? core_addr : display_addr),
	.addr_read(core_en ? core_addr : display_addr),
	.data_in, .data_out
);

tm1638_led_key_memmap
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHZ),
	.SEG7_COUNT(SEG7_COUNT),
	.LED_COUNT(0),
	.SEG7_BASE_ADDR(SEG7_BASE_ADDR),
	.LED_BASE_ADDR(0)
)
display_inst
(
	.i_clk(clk),
	.i_en(~core_en),	
	.o_read_addr(display_addr),
	.i_read_data(data_out),

	// shield pins
	.o_tm1638_clk(o_ledkey_clk),
	.o_tm1638_stb(o_ledkey_stb),
	.io_tm1638_data(io_ledkey_dio),

	.probe(probe),
	.o_idle(display_idle)
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
	.mem_write_data(data_in),
	.trace,
	.write_wait(core_write_wait)
);

enum {s_RESET, s_RUNNING
} state;

always @(posedge clk) begin
	if (!rst_n) begin
		state <= s_RESET;
	end
	else begin
		case (state)
		s_RESET: begin
			core_en <= 0;
			state <= s_RUNNING;
		end
		
		s_RUNNING: begin
			/*if (core_write_wait && core_addr >= SEG7_BASE_ADDR && core_addr < SEG7_BASE_ADDR + SEG7_COUNT)
				core_en <= 0;  // enable display
			else if (display_idle)
				core_en <= 1;*/
		end

		default:
			state <= s_RESET;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
