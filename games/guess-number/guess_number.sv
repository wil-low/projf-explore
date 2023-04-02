`default_nettype none
`timescale 1ns / 1ps

//`include "ir_nec_keys.svh"
// Infrared NEC protocol command codes
// full message: header, address, ~address, command, ~command

`define KEY_UP 8'h18
`define KEY_DOWN 8'h4A
`define KEY_LEFT 8'h10
`define KEY_RIGHT 8'h5A
`define KEY_OK 8'h38
`define KEY_1 8'hA2
`define KEY_2 8'h62
`define KEY_3 8'hE2
`define KEY_4 8'h22
`define KEY_5 8'h02
`define KEY_6 8'hC2
`define KEY_7 8'hE0
`define KEY_8 8'hA8
`define KEY_9 8'h90
`define KEY_0 8'h98
`define KEY_NUMERIC_STAR 8'h68
`define KEY_NUMERIC_POUND 8'hB0


module guess_number
#(
	parameter CLOCK_FREQ_Mhz
)
(
	input CLK,
	input RST_N,
	input [7:0] IR_DATA,
	input IR_DATA_READY,

	inout SCL,
	inout SDA,

	output [7:0] LED,
	output LED1,
	output LED2,
	output LED3
);

localparam ONE_USEC = CLOCK_FREQ_Mhz; // CLK / 1M

//// Game variables
localparam MAX_ATTEMPTS = 2;

logic [15:0] goal_number;
assign goal_number = {6'b0, lfsr_data[14:5]};
logic [15:0] user_number;
logic digit_entered;
logic [6:0] attempt_count;

//// Randomizer
logic [31:0] lfsr_seed = 0;
logic lfsr_seed_set = 0;
logic lfsr_en = 0;
logic lfsr_done;
logic [31:0] lfsr_data;

lfsr #(.NUM_BITS(32))
	lfsr_inst(
		.i_Clk(CLK),
		.i_Enable(lfsr_en),
		.i_Seed_DV(lfsr_seed_set),
		.i_Seed_Data(lfsr_seed),
		.o_LFSR_Data(lfsr_data),
		.o_LFSR_Done(lfsr_done)
 	);

//// BCD convertor for Attempts
logic bcd_en = 0;
logic [4 * 2 - 1:0] bcd_out;
logic bcd_ready;

bin2bcd #(.INPUT_WIDTH(7), .DECIMAL_DIGITS(2))
	bin2bcd_inst1(
		.i_Clock(CLK),
		.i_Binary(attempt_count),
		.i_Start(bcd_en),
		.o_BCD(bcd_out),
		.o_DV(bcd_ready)
	);

//// Liquid Crystal Display
logic enable = 1'b0;
logic rw = 1'b0;
logic send_2nd_nibble;
logic with_pulse;
logic data_mode = 1'b0;
logic backlight = 1'b0;
logic [7:0] mosi_data = 8'h0;
logic [7:0] miso_data;
logic busy;

/* verilator lint_off PINCONNECTEMPTY */
lc1602_i2c #(.DATA_WIDTH(8), .ADDR_WIDTH(7)) 
	lc1602_i2c_inst(
		.i_clk(CLK),
		.i_rst(~RST_N),
		.i_enable(enable),
		.i_rw(rw),
		.i_send_2nd_nibble(send_2nd_nibble),
		.i_with_pulse(with_pulse),
		.i_data_mode(data_mode),
		.i_backlight(backlight),
		.i_mosi_data(mosi_data),
		.i_device_addr(7'b010_0111),
		.i_divider(29),
		.o_miso_data(miso_data),
		.o_busy(busy),
		.io_sda(SDA),
		.io_scl(SCL)
	);

/* verilator lint_on PINCONNECTEMPTY */

//// LEDs
assign LED = (sm_state == S_SET_SEED) ? ~lfsr_seed[25 -: 8] : ~{1'b0, attempt_count};

//// State machine definitions

logic [28:0] wait_counter;
logic [28:0] wait_limit;

typedef enum {
	S_IDLE,
	S_PREINIT,
	S_PROC_EXEC_CMD,
	S_PROC_EXEC_CMD_READ,
	S_PROC_PRINT_OUTPUT_BUF,
	S_AFTER_INIT,
	S_SET_SEED,
	S_RANDOMIZE,
	S_CONVERT_ATTEMPT,
	S_AFTER_CONVERT_ATTEMPT,
	S_NUM_INPUT,
	S_CALC_USER_INPUT,
	S_MOVE_TO_OUTPUT,
	S_OUTPUT_ATTEMPT,
	S_CHECK_GUESS,
	S_AFTER_CHECK,
	S_AFTER_GAME_END
} SM_STATE;

SM_STATE sm_state, next_sm_state;

enum {
	C_FLAGS,
	C_DELAY1,
	C_DELAY2,
	C_DELAY3,
	C_DATA,
	C_CHAR
} cmd_state;

task ExecCmd;
	input [8:0] cmd_addr;
	input SM_STATE next_state;
begin
	sm_state <= S_PROC_EXEC_CMD;
	cmd_rom_addr <= cmd_addr;
	next_sm_state <= next_state;
end
endtask

//// Output buffer
logic [7:0] char_count;
logic [7:0] char_index;
logic [0 : 8 * 8 - 1] output_buf = "01: 0000";

//// Command memory file
`include "cmd_flags.svh"
`include "cmd.mem.svh"

logic [3:0] flags;
logic [27:0] delay_usec;
logic [7:0] str_len;

logic [8:0] cmd_rom_addr;
logic [7:0] cmd_rom_data;

rom_async #(
	.WIDTH(8),
	.DEPTH(`CmdMaxSize),
	.INIT_F("cmd.mem")
) cmd_rom (
	.addr(cmd_rom_addr),
	.data(cmd_rom_data)
);


//// Main cycle
always @(posedge CLK) begin
	if (!RST_N) begin
		sm_state <= S_PREINIT;
	end
	else begin
		if (busy)
			enable <= 0;
		lfsr_seed_set <= 0;

		case (sm_state)
			S_IDLE: begin
			end

			S_PREINIT: begin
				ExecCmd(`CmdInitAndWelcome, S_AFTER_INIT);
			end

			S_PROC_EXEC_CMD: begin
				wait_counter <= 0;
				wait_limit <= ONE_USEC * 50 * 1000;
				cmd_state <= C_FLAGS;
				sm_state <= S_PROC_EXEC_CMD_READ;
			end

			S_PROC_EXEC_CMD_READ: begin
				if (!busy) begin
					wait_counter <= wait_counter + 1;
					if (wait_counter == wait_limit) begin
						wait_counter <= 0;
						case (cmd_state)
							C_FLAGS: begin
								{flags, delay_usec[27 -: 4]} <= cmd_rom_data;
								cmd_rom_addr <= cmd_rom_addr + 1;
								wait_limit <= ONE_USEC;
								cmd_state <= C_DELAY1;
							end
							C_DELAY1: begin
								delay_usec[23 -: 8] <= cmd_rom_data;
								cmd_rom_addr <= cmd_rom_addr + 1;
								cmd_state <= C_DELAY2;
							end
							C_DELAY2: begin
								delay_usec[15 -: 8] <= cmd_rom_data;
								cmd_rom_addr <= cmd_rom_addr + 1;
								cmd_state <= C_DELAY3;
							end
							C_DELAY3: begin
								delay_usec[7 -: 8] <= cmd_rom_data;
								cmd_rom_addr <= cmd_rom_addr + 1;
								cmd_state <= C_DATA;
							end
							C_DATA: begin
								if (|(flags & `DATAMODE)) begin
									// need to print data
									str_len <= cmd_rom_data;
									cmd_state <= C_CHAR;
								end
								else begin
									if (delay_usec == 0) begin
										sm_state <= next_sm_state;  // return from sequence
									end
									else begin
										mosi_data <= cmd_rom_data;
										cmd_state <= C_FLAGS;
										enable <= 1;  // send command
										{data_mode, with_pulse, backlight, send_2nd_nibble} <= flags;
										wait_limit <= ONE_USEC * delay_usec;
									end
								end
								cmd_rom_addr <= cmd_rom_addr + 1;
							end
							C_CHAR: begin
								mosi_data <= cmd_rom_data;
								enable <= 1;  // send char
								{data_mode, with_pulse, backlight, send_2nd_nibble} <= flags;
								wait_limit <= ONE_USEC * delay_usec;
								cmd_rom_addr <= cmd_rom_addr + 1;
								str_len <= str_len - 1;
								if (str_len == 1) begin
									cmd_state <= C_FLAGS;
								end
							end

						endcase
					end
				end
			end

			S_AFTER_INIT: begin
				{LED1, LED2, LED3} = ~3'b0;
				sm_state <= S_SET_SEED;
			end

			S_SET_SEED: begin
				lfsr_seed <= lfsr_seed + 1;
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						lfsr_seed_set <= 1;
						lfsr_en <= 1;
						ExecCmd(`CmdShowRules, S_RANDOMIZE);
					end
				end
			end

			S_RANDOMIZE: begin
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						lfsr_en <= 0;
						attempt_count <= 1;
						digit_entered <= 0;
						ExecCmd(`CmdShowAttemptPrompt, S_CONVERT_ATTEMPT);
					end
				end
			end

			S_CONVERT_ATTEMPT: begin
				bcd_en <= 1;
				digit_entered <= 0;
				sm_state <= S_AFTER_CONVERT_ATTEMPT;
			end

			S_AFTER_CONVERT_ATTEMPT: begin
				bcd_en <= 0;
				if (bcd_ready) begin
					integer i;
					for (i = 0; i < 2; i = i + 1) begin
						output_buf[(2 - i) * 8 - 1 -: 8] <= {4'h3, bcd_out[i * 4 + 4 - 1 -: 4]};
					end
					sm_state <= S_NUM_INPUT;
				end
			end
			
			S_NUM_INPUT: begin
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						if (digit_entered)
							sm_state <= S_CHECK_GUESS;
					end
					else begin
						digit_entered <= 1;
						sm_state <= S_CALC_USER_INPUT;
						case (IR_DATA)
							`KEY_0: output_buf[32:63] <= {output_buf[40:63], "0"};
							`KEY_1: output_buf[32:63] <= {output_buf[40:63], "1"};
							`KEY_2: output_buf[32:63] <= {output_buf[40:63], "2"};
							`KEY_3: output_buf[32:63] <= {output_buf[40:63], "3"};
							`KEY_4: output_buf[32:63] <= {output_buf[40:63], "4"};
							`KEY_5: output_buf[32:63] <= {output_buf[40:63], "5"};
							`KEY_6: output_buf[32:63] <= {output_buf[40:63], "6"};
							`KEY_7: output_buf[32:63] <= {output_buf[40:63], "7"};
							`KEY_8: output_buf[32:63] <= {output_buf[40:63], "8"};
							`KEY_9: output_buf[32:63] <= {output_buf[40:63], "9"};
							default: begin
								digit_entered <= 0;
								sm_state <= S_NUM_INPUT;
							end
						endcase
					end
				end
				else
					char_count <= 0;
			end

			S_CALC_USER_INPUT: begin
				user_number <=  (output_buf[4 * 8 +: 8] - "0") * 1000 +
								(output_buf[5 * 8 +: 8] - "0")  * 100 +
								(output_buf[6 * 8 +: 8] - "0")  * 10 +
								(output_buf[7 * 8 +: 8] - "0");
				sm_state <= S_MOVE_TO_OUTPUT;
			end

			S_MOVE_TO_OUTPUT: begin
				ExecCmd(`CmdShowAttemptPrompt, S_OUTPUT_ATTEMPT);
			end

			S_OUTPUT_ATTEMPT: begin
				next_sm_state <= S_NUM_INPUT;
				sm_state <= S_PROC_PRINT_OUTPUT_BUF;
				char_index <= 0;
				char_count <= 8;
			end

			S_PROC_PRINT_OUTPUT_BUF: begin
				if (!busy) begin
					wait_counter <= wait_counter + 1;
					if (wait_counter == wait_limit) begin
						wait_counter <= 0;
						if (char_count != 0) begin
							if (char_index == char_count) begin
								sm_state <= next_sm_state;
							end
							else begin
								enable <= 1;  // send char
								mosi_data <= output_buf[char_index * 8 +: 8];
								{data_mode, with_pulse, backlight, send_2nd_nibble} <= `BACKLIGHT | `DATAMODE | `WITH_PULSE | `SEND_2ND_NIBBLE;
								wait_limit <= ONE_USEC * 10;
								char_index <= char_index + 1;
							end
						end
					end
				end
			end

			S_CHECK_GUESS: begin
				if (goal_number == user_number) begin
					{LED1, LED2, LED3} = ~3'b111;
					ExecCmd(`CmdSayVictory, S_AFTER_GAME_END);
				end
				else if (attempt_count >= MAX_ATTEMPTS) begin
					{LED1, LED2, LED3} = ~3'b101;
					ExecCmd(`CmdSayLost, S_AFTER_GAME_END);
				end
				else if (goal_number < user_number) begin
					{LED1, LED2, LED3} = ~3'b100;
					ExecCmd(`CmdSayLesser, S_AFTER_CHECK);
				end
				else if (goal_number > user_number) begin
					{LED1, LED2, LED3} = ~3'b001;
					ExecCmd(`CmdSayGreater, S_AFTER_CHECK);
				end
			end

			S_AFTER_CHECK: begin
				attempt_count <= attempt_count + 1;
				output_buf[32:63] <= "0000";
				sm_state <= S_CONVERT_ATTEMPT;
			end
			
			S_AFTER_GAME_END: begin
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						lfsr_en <= 1;
						attempt_count <= 0;
						{LED1, LED2, LED3} = ~3'b0;
						ExecCmd(`CmdShowRules, S_RANDOMIZE);
					end
				end
			end

			default:
				sm_state <= S_IDLE;
		endcase
	end
end

logic _unused_ok = &{1'b1, miso_data, 1'b0};

endmodule
