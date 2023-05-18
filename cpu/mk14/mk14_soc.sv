// MK14 cpu SoC

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module mk14_soc #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter DISPLAY_TIMEOUT_CYCLES = 5,
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

logic [$clog2(DISPLAY_TIMEOUT_CYCLES) - 1: 0] display_refresh_counter;

logic [7:0] data_in;
logic [7:0] data_out;

logic core_en = 1;
logic [15:0] core_addr;
logic core_write_en;

logic display_en;
logic [15:0] display_addr;
logic [7:0] display_data_out;
logic display_idle;

localparam SEG7_COUNT = 8;
localparam SEG7_BASE_ADDR = 'h100;

bram_sqp #(.WIDTH(8), .DEPTH(4 * 1024), .INIT_F(INIT_F))
memory_inst (
	.clk(clk),

	.we0(core_write_en),
	.addr_write0(core_addr),
	.addr_read0(core_addr),
	.data_in0(data_in),
	.data_out0(data_out),

	.we1(0),
	.addr_write1(display_addr),
	.addr_read1(display_addr),
	.data_in1(),
	.data_out1(display_data_out)
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
	.i_en(display_en),	
	.o_read_addr(display_addr),
	.i_read_data(display_data_out),

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
	.trace
);

typedef enum {s_RESET, s_RUNNING
} STATE;

STATE state = s_RESET;

always @(posedge clk) begin
	display_en <= 0;
	if (!rst_n) begin
		state <= s_RESET;
	end
	else begin
		case (state)
		s_RESET: begin
			core_en <= 1;
			display_refresh_counter <= DISPLAY_TIMEOUT_CYCLES;
			state <= s_RUNNING;
		end
		
		s_RUNNING: begin
			display_refresh_counter <= display_refresh_counter - 1;
			if (display_refresh_counter == 0) begin
				display_refresh_counter <= DISPLAY_TIMEOUT_CYCLES;
				if (display_idle)
					display_en <= 1;
			end
		end

		default:
			state <= s_RESET;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
