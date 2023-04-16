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
logic stack_push_en = 0;			// push enable (port a)
logic [55:0] stack_push_data;		// data to push (port a)
logic stack_pop_en = 0;		  		// pop enable (port a)
logic [55:0] stack_pop_data; 		// data to pop (port b)
logic stack_full;					// buffer is full
logic stack_empty;					// buffer is empty
logic [$clog2(STACK_DEPTH):0] stack_item_count;

stack #(.WIDTH(56), .DEPTH(STACK_DEPTH))
stack_inst(
	.clk, .rst_n(stack_rst_n),
	.push_en(stack_push_en), .push_data(stack_push_data),
	.pop_en(stack_pop_en), .pop_data(stack_pop_data),
	.full(stack_full), .empty(stack_empty), .item_count(stack_item_count)
);

enum {s_IDLE, s_PUSH_VALUE, s_INSTR, s_INSTR0_DONE, s_INSTR1_DONE, s_INSTR_STEP} state, next_state;

enum {ss_DUP} i_state;

assign executing = ((car & `CA_MASK) == `CA_NONE) || ((car & `CA_MASK) == `CA_EXEC);
assign acore_idle = (state == s_IDLE) && !push_en && !instr_en;

always_ff @(posedge clk) begin
	stack_push_en <= 0;
	stack_rst_n <= 1;

	if (!rst_n) begin
		{csp, dsp, dsp_s, ddc, ddc_s, dcr, pcp, ppr} <= 0;
		pcp <= 0;
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
				stack_push_data <= push_value;
				state <= s_PUSH_VALUE;
				next_state <= s_IDLE;
			end
			else if (instr_en) begin
				icr <= instr;
				state <= s_INSTR;
				next_state <= s_INSTR0_DONE;
			end
		end

		s_PUSH_VALUE: begin
			$display("PUSH_VALUE");
			stack_push_en <= 1;
			state <= next_state;
		end
		
		s_INSTR: begin
			$display("instr %h", icr & `MASK7);

			case (icr & `MASK7)

			`i_NOP: begin
				// do nothing
			end

			`i_DEPTH: begin
				stack_push_data <= stack_item_count + 1;
			end

			`i_DUP: begin
				//i_state <= ss_DUP
				//stack_push_data <= 
			end

			`i_EMPTY: begin
				stack_rst_n <= 0;
			end

			default: begin
				$display("Not implemented: %h", icr & `MASK7);
			end

			endcase

			//if (state == s_INSTR_STEP)
			state <= next_state;
		end

		s_INSTR0_DONE: begin
			$display("instr 0 done");
			icr <= icr >> 7;
			state <= s_INSTR;
			next_state <= s_INSTR1_DONE;
		end
		
		s_INSTR1_DONE: begin
			$display("instr 1 done");
			state <= s_IDLE;
		end

		default:
			state <= s_IDLE;

		endcase
		
	end

end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
