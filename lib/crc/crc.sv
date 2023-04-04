`default_nettype none
`timescale 1ns / 1ps

module crc
#(
	parameter WIDTH = 32,
	parameter POLY = 32'h04C11DB7,
	parameter INIT = 32'h0,
	parameter REF_IN = 1'b0,  // 0 — MSB-first, 1 — LSB-first
	parameter REF_OUT = 1'b0, // 1 - invert bit order for XOR input
	parameter XOR_OUT = 32'hFFFFFFFF,
	parameter DATA_LEN = WIDTH
)
(
	input i_clk,
	input [0 : DATA_LEN] i_data,
	input i_enable,
	output o_idle,
	output reg o_ready,
	output reg [0 : WIDTH - 1] o_result
);

enum {S_IDLE, S_INIT, S_PROCESS_BIT, S_DONE} sm_state;

localparam REAL_POLY = {1'b1, POLY};

localparam [WIDTH - 1 : 0] PADDING = 0;

assign o_idle = sm_state == S_IDLE;

logic [0 : DATA_LEN - 1 + WIDTH] saved_data;
logic [$clog2(DATA_LEN) - 1 : 0] bit_counter;

always @(posedge i_clk) begin

	case (sm_state)
		S_IDLE: begin
			if (i_enable) begin
				if (REF_IN)
					saved_data <= {PADDING, i_data};
				else
					saved_data <= {i_data, PADDING};
				sm_state <= S_INIT;
				o_ready <= 0;
			end
		end

		S_INIT: begin
			bit_counter <= 0;
			if (REF_IN)
				saved_data[WIDTH + DATA_LEN - 1 -: WIDTH] <= saved_data[WIDTH + DATA_LEN - 1 -: WIDTH] ^ INIT[0 +: WIDTH];
			else
				saved_data[0 +: WIDTH] <= saved_data[0 +: WIDTH] ^ INIT[0 +: WIDTH];
			sm_state <= S_PROCESS_BIT;
		end

		S_PROCESS_BIT: begin
			if (bit_counter == DATA_LEN) begin
				sm_state <= S_DONE;
			end
			else begin
				if (REF_IN) begin
					if (saved_data[WIDTH + DATA_LEN - 1 - bit_counter])
						saved_data[WIDTH + DATA_LEN - 1 - bit_counter -: WIDTH + 1] <= saved_data[WIDTH + DATA_LEN - 1 - bit_counter -: WIDTH + 1] ^ REAL_POLY;
				end
				else begin
					if (saved_data[bit_counter])
						saved_data[bit_counter +: WIDTH + 1] <= saved_data[bit_counter +: WIDTH + 1] ^ REAL_POLY;
				end
				bit_counter = bit_counter + 1;
			end
		end

		S_DONE: begin
			o_ready <= 1;
			sm_state <= S_IDLE;
			if (REF_IN)
				o_result <= saved_data[0 +: WIDTH] ^ XOR_OUT;
			else
				o_result <= saved_data[bit_counter +: WIDTH] ^ XOR_OUT;
		end

		default: begin
			sm_state <= S_IDLE;
		end
	endcase
end

endmodule
