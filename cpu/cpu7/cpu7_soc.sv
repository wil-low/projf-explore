// CPU7 cpu with cores

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module cpu7_soc #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter DELAY_REG_WIDTH = 36,	// max running time in microseconds
	parameter VREGS = 8,			// number of V-registers in this realisation
	parameter PROGRAM_SIZE = 1024,	// program size (in bytes)
	parameter MEM_SIZE = 4,			// memory size (in bytes)
	parameter DATA_STACK_DEPTH = 8,	// max item count in data stack
	parameter CALL_STACK_DEPTH = 8,	// max item count in call stack
	
	parameter USE_MUL = 1,
	parameter MUL_DATA_WIDTH = 56,
	parameter USE_DIV = 1,
	parameter DIV_DATA_WIDTH = 56,
	
	parameter PCP_WIDTH = $clog2(PROGRAM_SIZE),

	parameter CORES = 4,
	parameter INIT_F = ""
)
(
	input wire logic rst_n,
	input wire logic clk,
	output logic [11:0] trace
);

logic [$clog2(CORES) - 1:0] pxr = 0;  // process index register (core index in fact)
logic [DELAY_REG_WIDTH - 1:0] dlyc;  // free-running incremental delay counter

// active core data
logic [CORES - 1:0] acore_en;			// hot-one mask
logic [9 * CORES - 1: 0] acore_errcode;
logic [CORES - 1: 0] acore_executing;
logic [CORES - 1: 0] acore_delayed;
logic [CORES - 1: 0] acore_idle;		// core finished executing a command
logic [PCP_WIDTH * CORES - 1:0] acore_pcp;		// program code pointers
logic [8 * CORES - 1:0] acore_trace;	// trace from cores
logic [56 * CORES - 1:0] acore_mem_addr;	// memory addresses from cores
logic [CORES - 1:0] acore_mem_read8_en;		// read signal from cores
logic [8 * CORES - 1:0] acore_mem_write8;	// write byte from cores
logic [CORES - 1:0] acore_mem_write8_en;	// write signal from cores

logic [55:0] push_value;
logic push_en;
logic [13:0] instr;
logic instr_en;
logic pcp_step_en;

logic [55:0] mem_value;

logic [PCP_WIDTH - 1 : 0] addr_read;
logic [PCP_WIDTH - 1 : 0] addr_write = 0;
logic [15:0] data_in = 0;
logic [15:0] data_out;
logic write_en = 0;

localparam MEM_SIZE_WIDTH = $clog2(MEM_SIZE);
logic [MEM_SIZE_WIDTH - 1 : 0] mem_addr;
logic [7:0] mem_read_value;
logic [7:0] mem_write_value;
logic mem_write_en = 0;

assign addr_read = acore_pcp[(pxr + 1) * PCP_WIDTH - 1 -: PCP_WIDTH] / 2; // in words

assign trace[7:0] = acore_trace[(pxr + 1) * 8 - 1 -: 8];
assign trace[11:8] = state;

bram_sdp #(.WIDTH(16), .DEPTH(PROGRAM_SIZE / 2), .INIT_F(INIT_F))
program_inst (
	.clk_write(clk), .clk_read(clk), .we(write_en),
	.addr_write(addr_write), .addr_read(addr_read),
	.data_in, .data_out
);

bram_read_async #(.WIDTH(8), .DEPTH(MEM_SIZE), .INIT_F("/home/willow/prj/fpga-other/projf-explore/cpu/mc14500b/ice40_272p/cmd.mem"))
memory_inst (
	.clk, .we(mem_write_en),
	.addr_write(mem_addr), .addr_read(mem_addr),
	.data_in(mem_write_value), .data_out(mem_read_value)
);

genvar i;
generate
for (i = 0; i < CORES; i = i + 1) begin : generate_core
	core #(
		.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ),
		.VREGS(VREGS),
		.PROGRAM_SIZE(PROGRAM_SIZE),
		.DATA_STACK_DEPTH(DATA_STACK_DEPTH),
		.CALL_STACK_DEPTH(CALL_STACK_DEPTH),
		.USE_MUL(USE_MUL),
		.MUL_DATA_WIDTH(MUL_DATA_WIDTH),
		.USE_DIV(USE_DIV),
		.DIV_DATA_WIDTH(DIV_DATA_WIDTH),
		.CORE_INDEX(i),
		.MAX_THREADS(CORES)
	) core_inst (
		.rst_n(rst_n),
		.clk,
		.en(acore_en[i]),
		.push_value,
		.push_en,
		.instr,
		.instr_en,
		.pcp_step_en,
		.dlyc,
		.mem_read8(mem_read_value),
		.pcp(acore_pcp[(i + 1) * PCP_WIDTH - 1 -: PCP_WIDTH]),
		.executing(acore_executing[i]),
		.delayed(acore_delayed[i]),
		.errcode(acore_errcode[(i + 1) * 9 - 1 -: 9]),
		.trace(acore_trace[(i + 1) * 8 - 1 -: 8]),
		.idle(acore_idle[i]),
		.mem_addr(acore_mem_addr[(i + 1) * 56 - 1 -: 56]),
		.mem_read8_en(acore_mem_read8_en[i]),
		.mem_write8(acore_mem_write8[(i + 1) * 8 - 1 -: 8]),
		.mem_write8_en(acore_mem_write8_en[i])
	);
end
endgenerate

enum {s_RESET, s_HALT,
	s_BEFORE_READ, s_READ_WORD, s_DECODE_WORD, s_WAIT_PCP,
	s_WAIT_CORE, s_NEXT_CORE, s_NEXT_CORE_STEP, s_READ_MEM, s_WRITE_MEM
} state, next_state;

logic [7:0] bit_counter;

always @(posedge clk) begin
	pcp_step_en <= 0;
	instr_en <= 0;
	push_en <= 0;
	dlyc <= dlyc + 1;

	if (!rst_n) begin
		state <= s_RESET;
	end
	else begin
		case (state)
		s_RESET: begin
			// reset all cores
			pxr <= 0;
			dlyc <= 0;
			acore_en <= 1 << pxr;  // first core
			state <= s_BEFORE_READ;
			$display("\n=== Restart after RESET ===");
		end

		s_BEFORE_READ: begin
			//$display("s_BEFORE_READ addr_read %d, acore %d", addr_read, pxr);
			push_value <= 0;
			bit_counter <= 0;
			state <= s_READ_WORD;
		end
		
		s_READ_WORD: begin
			//$display("  (%h << %d) | %h", data_out & `MASK14, bit_counter, push_value);
			push_value <= ((data_out & `MASK14) << bit_counter) | push_value;
			state <= s_DECODE_WORD;
		end

		s_DECODE_WORD: begin
			//$display("s_DECODE_WORD addr_read %d, data_out %h, push_value %h, pxr %d", addr_read, data_out, push_value, pxr);
			bit_counter <= bit_counter + 14;
			pcp_step_en <= 1;
			state <= s_WAIT_CORE;
			next_state <= s_WAIT_PCP;
			if ((data_out & `WT_MASK) != `WT_DNL) begin
				if ((data_out & `WT_MASK) == `WT_CPU) begin
					instr <= data_out & `MASK14;
					instr_en <= 1;
					next_state <= s_NEXT_CORE;
					//$display("instr_en %h", data_out & `MASK14);
				end
				else if (((data_out & `WT_MASK) != `WT_IGN) && acore_executing[pxr]) begin
					push_en <= 1;
					next_state <= s_NEXT_CORE;
					//$display("push_en %h", push_value);
				end
			end
		end
		
		s_WAIT_PCP: begin
			state <= s_READ_WORD;
		end

		s_WAIT_CORE: begin
			//$display("s_WAIT_CORE %d, idle %b", pxr, acore_idle[pxr]);
			if (acore_mem_read8_en[pxr]) begin
				mem_write_en <= 0;
				write_en <= 0;
				if (acore_mem_addr[(pxr + 1) * 56 - 1 -: 56] >= PROGRAM_SIZE) begin
					mem_addr <= acore_mem_addr[(pxr + 1) * 56 - 1 -: 56] - PROGRAM_SIZE;
					state <= s_READ_MEM;
				end
				/*else begin
					mem_addr <= acore_mem_addr[(pxr + 1) * 56 - 1 -: 56];
					state <= s_READ_MEM;
				end*/
			end
			else if (acore_mem_write8_en[pxr]) begin
				mem_addr <= acore_mem_addr[(pxr + 1) * 56 - 1 -: 56] - PROGRAM_SIZE;
				mem_write_value <= acore_mem_write8[(pxr + 1) * 8 - 1 -: 8];
				mem_write_en <= 1;
				state <= s_WRITE_MEM;
			end
			else if (acore_idle[pxr])
				state <= next_state;
		end
		
		s_NEXT_CORE: begin
			if (|acore_errcode) begin  // errcode detected (always on active core)
				$display("\nCPU reset from core %d: errcode %h, addr %d",
					pxr,
					acore_errcode[(pxr + 1) * 9 - 1 -: 9],
					acore_pcp[(pxr + 1) * PCP_WIDTH - 1 -: PCP_WIDTH]);
				$display("Halt.\n");
				`ifdef SIMULATION
					$finish;
				`else
					state <= s_HALT;
				`endif
			end
			else begin
				$display("\n>>");
				pxr <= (pxr == CORES - 1) ? 0 : pxr + 1;
				state <= s_NEXT_CORE_STEP;
			end
		end

		s_NEXT_CORE_STEP: begin
			//$display("NEXT_CORE_STEP %d", pxr);
			// ignore cores that are executing delays
			if (acore_delayed[pxr])
				pxr <= (pxr == CORES - 1) ? 0 : pxr + 1;
			else begin
				acore_en <= 1 << pxr;
				state <= s_BEFORE_READ;
			end
		end

		s_READ_MEM: begin
			$display("mem_addr %d, mem_read_value %b, mem_write_value %b", mem_addr, mem_read_value, mem_write_value);
			state <= s_WAIT_CORE;
		end

		s_WRITE_MEM: begin
			$display("mem_addr %d, mem_read_value %b, mem_write_value %b", mem_addr, mem_read_value, mem_write_value);
			state <= s_WAIT_CORE;
		end

		s_HALT: begin
		end
		
		default:
			state <= s_RESET;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
