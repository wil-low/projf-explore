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
logic [55:0] r_a; // register R0 (A)
logic [55:0] r_b; // register R1 (B)
logic [55:0] r_c; // register R2 (C)
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

logic [63:0] dcr; // delay compare register, kept 0 if there is no active delay, otherwise contains the compare
logic [63:0] v_r[VREGS]; // variable registers

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
	s_IDLE, s_INSTR, s_INSTR_DONE,
	s_PUSH_PROC, s_POP_PROC, s_PEEK_PROC, s_POKE_PROC,
	s_OP_1, s_OP_2,
	s_DUP_STEP, s_PRINT_STACK_STEP, s_OP_1_STEP, s_OP_2_STEP, s_SWAP_STEP,
	s_ROT_STEP, s_OVER_STEP
} state, next_state;

assign executing = ((car & `CA_MASK) == `CA_NONE) || ((car & `CA_MASK) == `CA_EXEC);
assign acore_idle = (state == s_IDLE) && !push_en && !instr_en;

logic instr_counter;
logic [$clog2(STACK_DEPTH) - 1:0] step_counter;  // for multi-step instructions
logic [6:0] opcode;  // for generalized instructions

task reset;
input [13:0] errcode;
begin
	$display("CPU reset: errcode %h, addr %d", errcode, pcp);
	$display("Halt.\n");
`ifdef SIMULATION
	$finish;
`endif
end
endtask

always @(posedge clk) begin
	{stack_push_en, stack_pop_en, stack_peek_en, stack_poke_en} <= 0;
	stack_rst_n <= 1;

	if (!rst_n) begin
		{csp, dsp, dsp_s, ddc, ddc_s, dcr, pcp, ppr, stack_rst_n, pcp} <= 0;
		car <= `CA_NONE;
		state <= s_IDLE;
	end
	else if (en) begin
		//$display("  core %d pcp %d, state %d, next %d, pcp_step_en %b", IDX, pcp, state, next_state, pcp_step_en);

		case (state)

		s_IDLE: begin
			if (pcp_step_en) begin
				pcp <= pcp + 1;
			end

			if (push_en) begin
				stack_data_in <= push_value;
				state <= s_PUSH_PROC;
				next_state <= s_IDLE;
			end
			else if (instr_en) begin
				icr <= instr;
				opcode <= instr & `MASK7;
				instr_counter <= 1;
				state <= s_INSTR;
				next_state <= s_INSTR_DONE;
			end
		end

		s_PUSH_PROC: begin
			$display("PUSH_PROC %h", stack_data_in);
			if (stack_full) begin
				reset(`ERR_DSFULL);
			end
			else begin
				stack_push_en <= 1;
				state <= next_state;
			end
		end
		
		s_POP_PROC: begin
			$display("POP_PROC");
			if (stack_empty) begin
				reset(`ERR_DSEMPTY);
			end
			else begin
				stack_pop_en <= 1;
				state <= next_state;
			end
		end
		
		s_PEEK_PROC: begin
			$display("PEEK_PROC at %d", stack_index);
			if (stack_index >= stack_depth) begin
				reset(`ERR_DSINDEX);
			end
			else begin
				stack_peek_en <= 1;
				state <= next_state;
			end
		end
		
		s_POKE_PROC: begin
			$display("POKE_PROC at %d: %h", stack_index, stack_data_in);
			if (stack_index >= stack_depth) begin
				reset(`ERR_DSINDEX);
			end
			else begin
				stack_poke_en <= 1;
				state <= next_state;
			end
		end

		s_INSTR: begin
			$display("\ninstr %h %s", opcode, opcode2str(opcode));
			state <= s_INSTR_DONE;

			case (opcode)

			`i_NOP: begin
				// do nothing
			end

			`i_DEPTH: begin
				stack_data_in <= stack_depth + 1;
				state <= s_PUSH_PROC;
				next_state <= s_INSTR_DONE;
			end

			`i_DUP: begin
				stack_index <= 0;
				state <= s_PEEK_PROC;
				next_state <= s_DUP_STEP;
			end

			`i_EMPTY: begin
				stack_rst_n <= 0;
			end

			`i_PRINT_STACK: begin
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

			`i_DROP: begin
				state <= s_POP_PROC;
				next_state <= s_INSTR_DONE;
			end

			`i_SWAP: begin
				step_counter <= 5;
				state <= s_SWAP_STEP;
			end

			`i_ROT: begin
				step_counter <= 6;
				state <= s_ROT_STEP;
			end

			`i_OVER: begin
				step_counter <= 3;
				state <= s_OVER_STEP;
			end

			`i_COM,
			`i_NOT,
			`i_INC,
			`i_DEC: begin
				state <= s_OP_1;
			end

			`i_GT,
			`i_GTEQ,
			`i_SM,
			`i_SMEQ,
			`i_EQ,
			`i_NEQ,
			`i_AND,
			`i_OR,
			`i_XOR,
			`i_SHL,
			`i_SHR,
			`i_ADD,
			`i_SUB,
			`i_MUL,
			`i_DIV,
			`i_MOD:
			begin
				state <= s_OP_2;
			end

/* template
			`i_: begin
				$display("  ?");
			end
*/
			default: begin
				$display("  Not implemented: %h (%s)", opcode, opcode2str(opcode));
				reset(`ERR_INVALID);
			end

			endcase

		end

		s_INSTR_DONE: begin
			$display("instr %d done\n", instr_counter);
			if (instr_counter == 0) begin
				state <= s_IDLE;
			end
			else begin
				opcode <= icr >> 7;
				state <= s_INSTR;
				instr_counter <= instr_counter - 1;
			end
		end

		s_DUP_STEP: begin
			$display("DUP_STEP, stack_data_out %h", stack_data_out);
			stack_data_in <= stack_data_out;
			state <= s_PUSH_PROC;
			next_state <= s_INSTR_DONE;
		end

		s_OP_1: begin
			$display("OP_1 for opcode %h", opcode);
			stack_index <= 0;
			state <= s_PEEK_PROC;
			next_state <= s_OP_1_STEP;
		end

		s_OP_1_STEP: begin
			$display("OP_1_STEP for opcode %h", opcode);
			case (opcode)
			`i_COM:
				stack_data_in <= 1 + ~stack_data_out;
			`i_NOT:
				stack_data_in <= ~stack_data_out;
			`i_INC:
				stack_data_in <= stack_data_out + 1;
			`i_DEC:
				stack_data_in <= stack_data_out - 1;
			default:
				reset(`ERR_INVALID);
			endcase
			state <= s_POKE_PROC;
			next_state <= s_INSTR_DONE;
		end

		s_OP_2: begin
			$display("OP_2 for opcode %h", opcode);
			step_counter <= 3;
			state <= s_OP_2_STEP;
		end

		s_OP_2_STEP: begin
			next_state <= state;
			case (step_counter)
			3: begin
				state <= s_POP_PROC;
			end
			2: begin
				r_a <= stack_data_out;
				state <= s_POP_PROC;
			end
			1: begin
				state <= s_PUSH_PROC;
				case (opcode)
				`i_GT:
					stack_data_in <= stack_data_out > r_a ? 1 : 0;
				`i_GTEQ:
					stack_data_in <= stack_data_out >= r_a ? 1 : 0;
				`i_SM:
					stack_data_in <= stack_data_out < r_a ? 1 : 0;
				`i_SMEQ:
					stack_data_in <= stack_data_out <= r_a ? 1 : 0;
				`i_EQ:
					stack_data_in <= stack_data_out == r_a ? 1 : 0;
				`i_NEQ:
					stack_data_in <= stack_data_out != r_a ? 1 : 0;
				`i_AND:
					stack_data_in <= stack_data_out & r_a;
				`i_OR:
					stack_data_in <= stack_data_out | r_a;
				`i_XOR:
					stack_data_in <= stack_data_out ^ r_a;
				`i_SHL:
					stack_data_in <= stack_data_out << r_a;
				`i_SHR:
					stack_data_in <= stack_data_out >> r_a;
				`i_ADD:
					stack_data_in <= stack_data_out + r_a;
				`i_SUB:
					stack_data_in <= stack_data_out - r_a;
				`i_MUL:
					stack_data_in <= stack_data_out * r_a;
				`i_DIV:
					if (r_a == 0)
						reset(`ERR_CALC);
					else
						stack_data_in <= stack_data_out / r_a;
				`i_MOD:
					if (r_a == 0)
						reset(`ERR_CALC);
					else
						stack_data_in <= stack_data_out % r_a;
				default:
					reset(`ERR_INVALID);
				endcase
			end
			default: begin
				state <= s_INSTR_DONE;
			end
			endcase
			step_counter <= step_counter - 1;
		end

		s_SWAP_STEP: begin
			next_state <= state;
			case (step_counter)
			5: begin
				state <= s_POP_PROC;
			end
			4: begin
				if (stack_data_out == 0)
					state <= s_INSTR_DONE;  // nothing to do with 0 SWAP
				else begin
					stack_index <= stack_data_out; 
					$display("s_SWAP_STEP: %d", stack_data_out);
					r_a <= stack_data_out;  // remember N
					state <= s_PEEK_PROC;
				end
			end
			3: begin
				if (stack_data_out >= stack_depth)  //TODO: early check due to width mismatch
					reset(`ERR_DSINDEX);
				else begin
					r_a <= stack_data_out;  // remember Nth element
					stack_index <= 0;
					state <= s_PEEK_PROC;
				end
			end
			2: begin
				stack_data_in <= stack_data_out; // top element
				stack_index <= r_a;
				state <= s_POKE_PROC;
			end
			1: begin
				stack_data_in <= r_a;
				stack_index <= 0;
				state <= s_POKE_PROC;
			end
			default: begin
				state <= s_INSTR_DONE;
			end
			endcase
			step_counter <= step_counter - 1;
		end
		
		s_ROT_STEP: begin
			next_state <= state;
			case (step_counter)
			6: begin
				if (stack_depth < 3)
					reset(`ERR_DSINDEX);
				else
					state <= s_POP_PROC;
			end
			5: begin
				r_c <= stack_data_out;
				state <= s_POP_PROC;
			end
			4: begin
				r_b <= stack_data_out;
				state <= s_POP_PROC;
			end
			3: begin
				r_a <= stack_data_out;
				stack_data_in <= r_b;
				state <= s_PUSH_PROC;
			end
			2: begin
				stack_data_in <= r_c;
				state <= s_PUSH_PROC;
			end
			1: begin
				stack_data_in <= r_a;
				state <= s_PUSH_PROC;
			end
			default: begin
				state <= s_INSTR_DONE;
			end
			endcase
			step_counter <= step_counter - 1;
		end
		
		s_OVER_STEP: begin
			next_state <= state;
			case (step_counter)
			3: begin
				state <= s_POP_PROC;
			end
			2: begin
				stack_index <= stack_data_out; 
				state <= s_PEEK_PROC;
			end
			1: begin
				stack_data_in <= stack_data_out;
				state <= s_PUSH_PROC;
			end
			default: begin
				state <= s_INSTR_DONE;
			end
			endcase
			step_counter <= step_counter - 1;
		end

		s_PRINT_STACK_STEP: begin
			if (step_counter == 0) begin
				$display("    %d: %d", stack_index, stack_data_out);
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
