// CPU7 one core module

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module core #(
	parameter IDX = -1
)
(
	input logic rst_n,
	input logic clk,
	input logic en,					// core is selected to run
	input logic [55:0] push_value,	// constant value to push on stack
	input logic push_en,			// do push
	input logic [13:0] instr,		// instruction to execute
	input logic instr_en,			// do execute
	input logic pcp_step_en,		// advance pcp by 2
	output logic [27:0] pcp,		// program code pointer (...0)
	output logic executing,			// core status by condition action register
	output logic acore_idle			// core finished executing a command
);

localparam VREGS = 8;  // number of V-registers in this realisation
localparam STACK_DEPTH = 8;  // max item count in stack

logic [27:0] car; // conditional action register
					// only the two lowest order bits are monitored to determine the current condition
logic [27:0] r_a; // register R0 (A)
logic [27:0] r_b; // register R1 (B)
logic [27:0] r_c; // register R2 (C)
logic [13:0] r_d; // register R3 (D)
logic [13:0] r_e; // register R3 (E)

logic [13:0] icr; // instruction code register
					// contains two 7-bit instruction codes with the one in the lower
					// 7 bits executed first, and the one in the higher 7 bits executed second
logic [13:0] csp; // call stack pointer
logic [13:0] dsp; // data stack pointer
logic [13:0] dsp_s; // data stack pointer snapshot
logic [13:0] ddc; // data stack depth counter
logic [13:0] ddc_s; // data stack depth counter snapshot
logic [13:0] ppr; // process priority register

logic [27:0] dcr; // delay compare register, kept 0 if there is no active delay, otherwise contains the compare
logic [27:0] v_r[VREGS]; // variable registers

logic stack_rst_n = 1;
logic stack_push_en = 0;			// push enable (add on top)
logic stack_pop_en = 0;				// pop enable (remove from top)
logic stack_peek_en = 0;			// peek enable (return item at index, no change)
logic stack_poke_en = 0;			// poke enable (replace item at index)
logic [55:0] stack_data_in;			// data to push|poke
logic [55:0] stack_data_out; 		// data returned for pop|peek
logic stack_full;					// buffer is full
logic stack_empty;					// buffer is empty
logic [$clog2(STACK_DEPTH):0] stack_index;  // element index t (0 is top)
logic [$clog2(STACK_DEPTH):0] stack_depth;  // returns how many items are in stack

stack #(.WIDTH(56), .DEPTH(STACK_DEPTH))
stack_inst(
	.clk,
	.rst_n(stack_rst_n),
	.push_en(stack_push_en),
	.pop_en(stack_pop_en),
	.peek_en(stack_peek_en),
	.poke_en(stack_poke_en),
	.index(stack_index),
	.data_in(stack_data_in),
	.data_out(stack_data_out),
	.full(stack_full),
	.empty(stack_empty),
	.depth(stack_depth)
);

enum {
	s_IDLE, s_PUSH_VALUE, s_INSTR, s_INSTR_DONE,
	s_DUP_STEP, s_PRINT_STACK_STEP
} state, next_state;

assign executing = ((car & `CA_MASK) == `CA_NONE) || ((car & `CA_MASK) == `CA_EXEC);
assign acore_idle = (state == s_IDLE) && !push_en && !instr_en;

logic instr_counter;
logic [$clog2(STACK_DEPTH) - 1:0] step_counter;  // for multi-step instructions

always_ff @(posedge clk) begin
	{stack_push_en, stack_pop_en, stack_peek_en, stack_poke_en} <= 0;
	stack_rst_n <= 1;

	if (!rst_n) begin
		{csp, dsp, dsp_s, ddc, ddc_s, dcr, pcp, ppr, stack_rst_n, pcp} <= 0;
		car <= `CA_NONE;
		state <= s_IDLE;
	end
	else if (en) begin
		//$display("core %d pcp %h, state %d, next %d", IDX, pcp, state, next_state);
		if (pcp_step_en)
			pcp <= pcp + 1;

		case (state)

		s_IDLE: begin
			if (push_en) begin
				stack_data_in <= push_value;
				state <= s_PUSH_VALUE;
				next_state <= s_IDLE;
			end
			else if (instr_en) begin
				icr <= instr;
				instr_counter <= 1;
				state <= s_INSTR;
				next_state <= s_INSTR_DONE;
			end
		end

		s_PUSH_VALUE: begin
			$display("PUSH_VALUE %h", stack_data_in);
			stack_push_en <= 1;
			state <= next_state;
		end
		
		s_INSTR: begin
			//$display("\ninstr %h", icr & `MASK7);
			state <= s_INSTR_DONE;

			case (icr & `MASK7)

			`i_NOP: begin
				$display("  NOP");
				// do nothing
			end

			`i_DEPTH: begin
				$display("  DEPTH");
				stack_data_in <= stack_depth + 1;
				state <= s_PUSH_VALUE;
				next_state <= s_INSTR_DONE;
			end

			`i_DUP: begin
				$display("  DUP");
				stack_index <= 0;
				stack_peek_en <= 1;
				state <= s_DUP_STEP;
			end

			`i_EMPTY: begin
				$display("  EMPTY");
				stack_rst_n <= 0;
			end

			`custom_PRINT_STACK: begin
				$display("PRINT_STACK depth %d", stack_depth);
				if (stack_empty)
					$display("PRINT_STACK end");
				else begin
					stack_index <= 0;
					stack_peek_en <= 1;
					step_counter <= 1;
					state <= s_PRINT_STACK_STEP;
				end
			end

/* template
			`i_: begin
				$display("  ?");
			end
*/
			default: begin
				$display("  Not implemented: %h", icr & `MASK7);
				reset(`ERR_INVALID, pcp);
			end

			endcase

		end

		s_INSTR_DONE: begin
			$display("instr %d done\n", instr_counter);
			if (instr_counter == 0) begin
				state <= s_IDLE;
			end
			else begin
				icr <= icr >> 7;
				state <= s_INSTR;
				instr_counter <= instr_counter - 1;
			end
		end

		s_DUP_STEP: begin
			$display("DUP_STEP, stack_data_out %h", stack_data_out);
			stack_data_in <= stack_data_out;
			state <= s_PUSH_VALUE;
			next_state <= s_INSTR_DONE;
		end

		s_PRINT_STACK_STEP: begin
			if (step_counter == 0) begin
				$display("    %d: %h", stack_index, stack_data_out);
				if (stack_index == stack_depth - 1) begin
					state <= s_INSTR_DONE;
					$display("PRINT_STACK end");
				end
				else begin
					stack_index <= stack_index + 1;
					stack_peek_en <= 1;
				end
			end
			else
				step_counter <= step_counter - 1;
		end

		default:
			state <= s_IDLE;

		endcase
		
	end

end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
