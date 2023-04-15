// CPU7 cpu with cores

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module cpu7_soc #(
	parameter CORES = 4,
	parameter INIT_F = ""
)
(
	input logic rst_n,
	input logic clk
);

logic [6:0] pxr = 0;  // process index register (core index in fact)
logic [55:0] dlyc;  // free-running incremental delay counter

// active core data
logic [CORES - 1:0] acore_en;  // hot-one mask
logic acore_executing[CORES];
logic [27:0] acore_pcp[CORES];  // program code pointers

logic [55:0] push_value;
logic push_en;
logic [13:0] instr;
logic instr_en;
logic pcp_step_en;

logic [27:0] addr_read;
logic [27:0] addr_write;
logic [15:0] data_in;
logic [15:0] data_out;
logic write_en = 0;

bram_sdp #(.WIDTH(16), .DEPTH(256), .INIT_F(INIT_F))
bram_sdp_inst (
	.clk_write(clk), .clk_read(clk), .we(write_en),
	.addr_write, .addr_read,
	.data_in, .data_out
);

genvar i;
for (i = 0; i < CORES; i = i +1)
	core core_inst (
		.rst_n, .clk, .en(acore_en[i]),
		.push_value, .push_en, .instr, .instr_en, .pcp_step_en,
		.pcp(acore_pcp[i]), .executing(acore_executing[i])
	);

enum {s_RESET, s_BEFORE_READ, s_READ_WORD, s_NEXT_CORE} state;

logic [27:0] read_accum;
logic [13:0] bit_counter;

always_ff @(posedge clk) begin
	pcp_step_en <= 0;
	instr_en <= 0;
	push_en <= 0;

	case (state)
	s_RESET: begin
		// reset all cores
		acore_en <= 1 << pxr;  // first core
		addr_read <= acore_pcp[pxr];
		state <= s_BEFORE_READ;
	end

	s_BEFORE_READ: begin
		read_accum <= 0;
		bit_counter <= 0;
		state <= s_READ_WORD;
	end
	
	s_READ_WORD: begin
		read_accum <= ((data_out & `MASK14) << bit_counter) | read_accum;
		pcp_step_en <= 1;
		if ((data_out & `WT_MASK) != `WT_DNL) begin
			if ((data_out & `WT_MASK) == `WT_CPU) begin
				instr <= data_out & `MASK14;
				instr_en <= 1;
				state <= s_NEXT_CORE;
			end
			else if (((data_out & `WT_MASK) == `WT_IGN) && acore_executing[pxr]) begin
				push_value <= read_accum;
				push_en <= 1;
				state <= s_NEXT_CORE;
			end
		end
	end
	
	s_NEXT_CORE: begin
		state <= s_BEFORE_READ;
	end
	
	default:
		state <= s_RESET;

	endcase
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
