// MK14 one core module

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

module core #(
	parameter CLOCK_FREQ_MHZ = 50	// clock frequency == ticks in 1 microsecond
)
(
	input wire logic rst_n,
	input wire logic clk,
	input wire logic en,

	output logic [15:0] mem_addr,
	input wire logic [7:0] mem_read_data,
	output logic mem_write_en,
	output logic [7:0] mem_write_data,
	output logic [7:0] trace
);

`ifdef SIMULATION
localparam ONE_MSEC = 1;
`else
localparam ONE_MSEC = CLOCK_FREQ_MHZ * 1000;
`endif

//============ Registers ============
logic [7:0] AC = 0;		// Accumulator
logic [7:0] E= 0;		// Extension Register

assign trace = E;//PC[7:0];//E;

// Status Register
// {CY_L, OV, SB, SA, IE, F2, F1, F0}
logic F0 = 0;		// User assigned flags
logic F1 = 0;
logic F2 = 0;
logic IE = 0;		// Interrupt Enable
logic SA = 0;		// Read-only sense inputs. If IE=1, SA is interrupt input
logic SB = 0;
logic OV = 0;		// Overflow, set or reset by arithmetic operations
logic CY_L = 0;		// Carry/Link, set or reset by arithmetic operations or rotate with Link

logic [15:0] PC = 0;// Program Counter
logic [15:0] P1 = 0;// Pointer registers. P3 doubles as interrupt vector
logic [15:0] P2 = 0;
logic [15:0] P3 = 0;

logic [16 * 4 - 1:0] REG_WIRE;
assign REG_WIRE = {P3, P2, P1, PC};

//============ Internal registers ============
logic [7:0] opcode;	// store current opcode (1st byte)

logic [29:0] delay_cycles;

logic [15:0] PTR;
assign PTR = REG_WIRE[opcode[1:0] * 16 + 15 -: 16];

//============ State machine ============
enum {
	s_IDLE, s_FETCH, s_MEM_WAIT, s_SET_OPCODE, s_DECODE, s_EXEC_IMM,
	s_LOAD_INC_DEC, s_EXEC_INC_DEC, s_STORE_INC_DEC,
	s_EXEC_JUMP, s_CALC_DELAY, s_EXEC_DELAY,
	s_LOAD_FROM_EA, s_STORE_TO_EA, s_EXEC_MEM, s_HALT, s_UNKNOWN
} state, next_state;

always @(posedge clk) begin

	if (!rst_n) begin
		{CY_L, OV, SB, SA, IE, F2, F1, F0} <= 0;
		{AC, E, PC, P1, P2, P3} <= 0;
		state <= s_IDLE;
	end
	else if (en) begin
		mem_write_en <= 0;

		case (state)

		s_IDLE: begin
			state <= s_FETCH;
		end

		s_FETCH: begin
			mem_addr <= PC + 1;
			PC <= PC + 1;
			state <= s_MEM_WAIT;
			next_state <= s_SET_OPCODE;
		end

		s_MEM_WAIT: begin
			state <= next_state;
		end

		s_SET_OPCODE: begin
			opcode <= mem_read_data;
			state <= s_DECODE;
		end

		s_DECODE: begin
			//$display("Decode PC %h, opcode %h", PC, opcode);
			state <= s_FETCH;
			casez (opcode)

			// == Immediate ==
			`i_LDI,
			`i_ANI,
			`i_ORI,
			`i_XRI,
			`i_DAI,
			`i_ADI,
			`i_CAI: begin
				mem_addr <= PC + 1;
				PC <= PC + 1;
				state <= s_MEM_WAIT;
				next_state <= s_EXEC_IMM;
			end

			// == Extension Register ==
			`i_LDE: begin
				AC <= E;
			end
			`i_XAE: begin
				AC <= E;
				E <= AC;
			end
			`i_ANE: begin
				AC <= AC & E;
			end
			`i_ORE: begin
				AC <= AC | E;
			end
			`i_XRE: begin
				AC <= AC ^ E;
			end
			`i_DAE: begin
				state <= s_UNKNOWN;
			end
			`i_ADE: begin
				{OV, CY_L, AC} <= AC + E + CY_L;
			end
			`i_CAE: begin
				{OV, CY_L, AC} <= AC + ~E + CY_L;
			end

			`i_SIO: begin
				state <= s_UNKNOWN;
			end
			`i_SR: begin
				AC <= AC >> 1;
			end
			`i_SRL: begin
				AC <= {CY_L, AC[7:1]};
			end
			`i_RR: begin
				AC <= {AC[0], AC[7:1]};
			end
			`i_RRL: begin
				{CY_L, AC} <= {AC[0], CY_L, AC[7:1]};
			end
			
			`i_DLY: begin
				mem_addr <= PC + 1;
				PC <= PC + 1;
				state <= s_MEM_WAIT;
				next_state <= s_CALC_DELAY;
			end

			`i_HALT: begin
				state <= s_HALT;
			end
			`i_CCL: begin
				CY_L <= 0;
			end
			`i_SCL: begin
				CY_L <= 1;
			end
			`i_DINT: begin
				IE <= 0;
			end
			`i_IEN: begin
				IE <= 1;
			end
			`i_CSA: begin
				AC <= {CY_L, OV, SB, SA, IE, F2, F1, F0};
			end
			`i_CAS: begin
				{CY_L, OV, SB, SA, IE, F2, F1, F0} <= AC;
			end
			`i_NOP: begin
			end

			// casez cases below

			// == Memory reference ==
			`i_ST: begin
				mem_addr <= PC + 1;
				PC <= PC + 1;
				state <= s_MEM_WAIT;
				//$display("PC=%h: ST AC %h", PC, AC);
				next_state <= s_STORE_TO_EA;
			end
			`i_LD,
			`i_AND,
			`i_OR,
			`i_XOR,
			`i_DAD,
			`i_ADD,
			`i_CAD: begin
				mem_addr <= PC + 1;
				PC <= PC + 1;
				state <= s_MEM_WAIT;
				next_state <= s_LOAD_FROM_EA;
			end

			`i_ILD,
			`i_DLD: begin
				mem_addr <= PC + 1;
				PC <= PC + 1;
				state <= s_MEM_WAIT;
				next_state <= s_LOAD_INC_DEC;
			end

			`i_JMP,
			`i_JP,
			`i_JZ,
			`i_JNZ: begin
				mem_addr <= PC + 1;
				PC <= PC + 1;
				state <= s_MEM_WAIT;
				next_state <= s_EXEC_JUMP;
			end

			`i_XPAL: begin
				case (opcode[1:0])
				1: begin
					AC <= P1[7:0];
					P1[7:0] <= AC;
				end
				2: begin
					AC <= P2[7:0];
					P2[7:0] <= AC;
				end
				3: begin
					AC <= P3[7:0];
					P3[7:0] <= AC;
				end
				default: ;
				endcase
			end
			`i_XPAH: begin
				case (opcode[1:0])
				1: begin
					AC <= P1[15:8];
					P1[15:8] <= AC;
				end
				2: begin
					AC <= P2[15:8];
					P2[15:8] <= AC;
				end
				3: begin
					AC <= P3[15:8];
					P3[15:8] <= AC;
				end
				default: ;
				endcase
			end
			`i_XPPC: begin
				case (opcode[1:0])
				1: begin
					PC <= P1;
					P1 <= PC;
				end
				2: begin
					PC <= P2;
					P2 <= PC;
				end
				3: begin
					PC <= P3;
					P3 <= PC;
				end
				default: ;
				endcase
			end

			default:
				state <= s_UNKNOWN;
			endcase
		end

		s_EXEC_IMM: begin
			state <= s_FETCH;
			// == Immediate ==
			case (opcode)
			`i_LDI: begin
				AC <= mem_read_data;
			end
			`i_ANI: begin
				AC <= AC & mem_read_data;
			end
			`i_ORI: begin
				AC <= AC | mem_read_data;
			end
			`i_XRI: begin
				AC <= AC ^ mem_read_data;
			end
			`i_DAI: begin
				state <= s_UNKNOWN;
			end
			`i_ADI: begin
				{OV, CY_L, AC} <= AC + mem_read_data + CY_L;
			end
			`i_CAI: begin
				{OV, CY_L, AC} <= AC + ~mem_read_data + CY_L;
			end
			default:
				state <= s_UNKNOWN;
			endcase
		end

		s_LOAD_INC_DEC: begin
			mem_addr <= $signed(PTR) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
			state <= s_MEM_WAIT;
			next_state <= s_EXEC_INC_DEC;
		end

		s_EXEC_INC_DEC: begin
			AC <= mem_read_data + (opcode[4] == 0 ? 1 : -1);
			state <= s_STORE_INC_DEC;
		end

		s_STORE_INC_DEC: begin
			//$display("s_STORE_INC_DEC AC %h", AC);
			mem_write_data <= AC;
			mem_write_en <= 1;
			state <= s_MEM_WAIT;
			next_state <= s_FETCH;
		end

		s_STORE_TO_EA: begin
			if (opcode[2]) begin  // auto-index
				case (opcode[1:0])
				1: P1 <= $signed(P1) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
				2: P2 <= $signed(P2) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
				3: P3 <= $signed(P3) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
				default: ;
				endcase

				if ($signed(mem_read_data) >= 0)
					mem_addr <= PTR;
				else
					mem_addr <= $signed(PTR) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
			end
			else begin
				mem_addr <= $signed(PTR) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
			end
			mem_write_data <= AC;
			mem_write_en <= 1;
			state <= s_MEM_WAIT;
			next_state <= s_FETCH;
		end

		s_LOAD_FROM_EA: begin
			$display("PC %h, s_LOAD_FROM_EA: PTR %h, unsigned=%d, signed = %d, opcode %h, EA %h, E %h", PC, $signed(PTR), mem_read_data, $signed(mem_read_data), opcode, $signed(PTR) + (mem_read_data == 'h80 ? E : $signed(mem_read_data)), E);
			if (opcode[2]) begin  // auto-index
				case (opcode[1:0])
				1: P1 <= $signed(P1) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
				2: P2 <= $signed(P2) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
				3: P3 <= $signed(P3) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
				default: ;
				endcase

				if ($signed(mem_read_data) >= 0)
					mem_addr <= PTR;
				else
					mem_addr <= $signed(PTR) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
			end
			else begin
				mem_addr <= $signed(PTR) + $signed(mem_read_data == 'h80 ? E : mem_read_data);
			end
			state <= s_MEM_WAIT;
			next_state <= s_EXEC_MEM;
		end

		s_EXEC_MEM: begin
			$display("mem_addr=%h, opcode=%h", mem_addr, opcode);
			state <= s_FETCH;
			// == Immediate ==
			casez (opcode)
			`i_LD: begin
				AC <= mem_read_data;
			end
			`i_AND: begin
				AC <= AC & mem_read_data;
			end
			`i_OR: begin
				AC <= AC | mem_read_data;
			end
			`i_XOR: begin
				AC <= AC ^ mem_read_data;
			end
			`i_DAD: begin
				state <= s_UNKNOWN;
			end
			`i_ADD: begin
				{OV, CY_L, AC} <= AC + mem_read_data + CY_L;
			end
			`i_CAD: begin
				{OV, CY_L, AC} <= AC + ~mem_read_data + CY_L;
			end
			default:
				state <= s_UNKNOWN;
			endcase
		end

		s_EXEC_JUMP: begin
			//$display("mem_addr=%d, opcode=%h", mem_addr, opcode);
			state <= s_FETCH;
			// == Immediate ==
			casez (opcode)
			`i_JMP: begin
				PC <= $signed(PTR) + $signed(mem_read_data);
			end
			`i_JP: begin
				//$display("JP AC %d, cond %d", AC, $signed(AC) >= 0);
				if ($signed(AC) >= 0)
					PC <= $signed(PTR) + $signed(mem_read_data);
			end
			`i_JZ: begin
				if (AC == 0)
					PC <= $signed(PTR) + $signed(mem_read_data);
			end
			`i_JNZ: begin
				if (AC)
					PC <= $signed(PTR) + $signed(mem_read_data);
			end
			default:
				state <= s_UNKNOWN;
			endcase
		end
		
		s_CALC_DELAY: begin
			delay_cycles <= mem_read_data * 2 * ONE_MSEC;
			$display("PC %h: DLY cycles %d, AC %d, E %d\n", PC, mem_read_data * 2, AC, E);
			state <= s_EXEC_DELAY;
		end

		s_EXEC_DELAY: begin
			if (AC == 8'hff) begin
				state <= s_FETCH;
			end
			else begin
				if (delay_cycles == 0) begin
					AC <= AC - 1;
					//$display("PC %h: s_EXEC_DELAY AC %d, %d", PC, AC, mem_read_data * 2);
					delay_cycles <= mem_read_data * 2 * ONE_MSEC;
				end
				else
					delay_cycles <= delay_cycles - 1;
			end
		end

		s_HALT: begin
			$display("HALT at %h, AC %h, E %h\n", PC, AC, E);
			`ifdef SIMULATION
				$finish;
			`endif
		end

		s_UNKNOWN: begin
			$display("PC %h: Unknown opcode %h - halt.\n", PC, opcode);
			`ifdef SIMULATION
				$finish;
			`endif
		end

		default:
			state <= s_IDLE;

		endcase
		
	end

end

endmodule
