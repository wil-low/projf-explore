// CPU7 cpu with cores

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module cpu7_soc #(
	parameter CORES = 4,
	parameter PROGRAM_SIZE = 256,
	parameter INIT_F = ""
)
(
	input logic rst_n,
	input logic clk,
	output logic [7:0] trace
);

logic [$clog2(CORES) - 1:0] pxr = 0;  // process index register (core index in fact)
logic [55:0] dlyc;  // free-running incremental delay counter

// active core data
logic [CORES - 1:0] acore_en;			// hot-one mask
logic [CORES - 1: 0] acore_executing;
logic [CORES - 1: 0] acore_idle;		// core finished executing a command
logic [28 * CORES - 1:0] acore_pcp;		// program code pointers

logic [55:0] push_value;
logic push_en;
logic [13:0] instr;
logic instr_en;
logic pcp_step_en;

logic [13:0] addr_read;
logic [13:0] addr_write = 0;
logic [15:0] data_in = 0;
logic [15:0] data_out;
logic write_en = 0;

assign addr_read = acore_pcp[(pxr + 1) * 28 - 1 -: 28];

assign trace = addr_read;

bram_read_async #(.WIDTH(16), .DEPTH(PROGRAM_SIZE), .INIT_F(INIT_F))
bram_read_async (
	.clk, .we(write_en),
	.addr_write, .addr_read,
	.data_in, .data_out
);

genvar i;
generate
for (i = 0; i < CORES; i = i + 1) begin : generate_core
	core #(.IDX(i)) core_inst (
		.rst_n(rst_n), .clk, .en(acore_en[i]),
		.push_value, .push_en, .instr, .instr_en, .pcp_step_en,
		.pcp(acore_pcp[(i + 1) * 28 - 1 -: 28]), .executing(acore_executing[i]),
		.acore_idle(acore_idle[i])
	);
end
endgenerate

enum {s_RESET, s_BEFORE_READ, s_READ_WORD, s_DECODE_WORD, s_WAIT_CORE, s_NEXT_CORE} state, next_state;

logic [55:0] read_accum;
logic [13:0] bit_counter;

always @(posedge clk) begin
	pcp_step_en <= 0;
	instr_en <= 0;
	push_en <= 0;

	if (!rst_n) begin
		state <= s_RESET;
	end
	else begin
		case (state)
		s_RESET: begin
			// reset all cores
			pxr <= 0;
			acore_en <= 1 << pxr;  // first core
			state <= s_BEFORE_READ;
		end

		s_BEFORE_READ: begin
			$display("s_BEFORE_READ addr_read %d, acore %d", addr_read, pxr);
			read_accum <= 0;
			bit_counter <= 0;
			state <= s_READ_WORD;
		end
		
		s_READ_WORD: begin
			//$display("  (%h << %d) | %h", data_out & `MASK14, bit_counter, read_accum);
			read_accum <= ((data_out & `MASK14) << bit_counter) | read_accum;
			state <= s_DECODE_WORD;
		end

		s_DECODE_WORD: begin
			$display("s_DECODE_WORD addr_read %d, data_out %h, read_accum %h, pxr %d", addr_read, data_out, read_accum, pxr);
			bit_counter <= bit_counter + 14;
			pcp_step_en <= 1;
			state <= s_WAIT_CORE;
			next_state <= s_READ_WORD;
			if ((data_out & `WT_MASK) != `WT_DNL) begin
				if ((data_out & `WT_MASK) == `WT_CPU) begin
					instr <= data_out & `MASK14;
					instr_en <= 1;
					next_state <= s_NEXT_CORE;
					$display("instr_en %h", data_out & `MASK14);
				end
				else if (((data_out & `WT_MASK) != `WT_IGN) && acore_executing[pxr]) begin
					push_value <= read_accum;
					push_en <= 1;
					next_state <= s_NEXT_CORE;
					$display("push_en %h", read_accum);
				end
			end
		end
		
		s_WAIT_CORE: begin
			//$display("s_WAIT_CORE %d, idle %b", pxr, acore_idle[pxr]);
			if (acore_idle[pxr])
				state <= next_state;
		end
		
		s_NEXT_CORE: begin
			$display("==== Next core ====");
			state <= s_BEFORE_READ;
		end
		
		default:
			state <= s_RESET;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
