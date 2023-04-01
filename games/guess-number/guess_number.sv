`default_nettype none
`timescale 1ns / 1ps

`include "../../../lib/infrared/ir_nec_keys.svh"

module guess_number
#(
	parameter CLOCK_FREQ_Mhz
)
(
	input CLK,
	input BTN1,
	input [7:0] IR_DATA,
	input IR_DATA_READY,

	inout SCL,
	inout SDA,

	output [7:0] LED,
	output LED1,
	output LED2,
	output LED4
);

logic [7:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

logic enable = 1'b0;
logic rw = 1'b0;
logic send_2nd_nibble;
logic with_pulse;
logic data_mode = 1'b0;
logic backlight = 1'b0;
logic [7:0] mosi_data = 8'h0;
logic [7:0] miso_data;
logic busy;

logic debug = 0;

logic [31:0] lfsr_seed = 0;
logic lfsr_seed_set = 0;
logic lfsr_en = 0;
logic lfsr_done;
logic [31:0] lfsr_data;

logic [15:0] goal_number = {6'b0, lfsr_data[14:5]};
logic [15:0] user_number;
logic [6:0] attempt_count;

lfsr #(.NUM_BITS(32))
	lfsr_inst(
		.i_Clk(CLK),
		.i_Enable(lfsr_en),
		.i_Seed_DV(lfsr_seed_set),
		.i_Seed_Data(lfsr_seed),
		.o_LFSR_Data(lfsr_data),
		.o_LFSR_Done(lfsr_done)
 	);

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

/* verilator lint_off PINCONNECTEMPTY */
lc1602_i2c #(.DATA_WIDTH(8), .ADDR_WIDTH(7)) 
	lc1602_i2c_inst(
		.i_clk(CLK),
		.i_rst(~rst_n),
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

assign LED = ~user_number[7:0];
//assign LED1 = ~ir_data_ready;
assign LED2 = ~debug;

localparam ONE_USEC = 12; // CLK / 1M

logic [28:0] wait_counter;
logic [28:0] wait_limit;

enum {
	S_IDLE,
	S_PREINIT,
	S_PROC_EXEC_CMD,
	S_AFTER_INIT,
	S_CLEAR_INPUT,
	S_NUM_INPUT,
	S_PROC_PRINT_OUTPUT_BUF,
	S_SHOW_USER_INPUT,
	S_CONVERT_ATTEMPT,
	S_OUTPUT_ATTEMPT,
	S_CHECK_GUESS,
	S_AFTER_CHECK,
	S_AFTER_VICTORY
} sm_state, next_sm_state;

enum {
	C_FLAGS,
	C_DELAY1,
	C_DELAY2,
	C_DELAY3,
	C_DATA,
	C_CHAR
} cmd_state;

logic [8:0] cmd_rom_addr;
logic [7:0] cmd_rom_data;

logic [7:0] char_count;
logic [7:0] char_index;

localparam OUTPUT_WIDTH = 4;
logic [0 : 8 * OUTPUT_WIDTH - 1] output_buf = {OUTPUT_WIDTH{"0"}};

`include "cmd_flags.svh"
`include "cmd.mem.svh"

rom_async #(
	.WIDTH(8),
	.DEPTH(`CmdMaxSize),
	.INIT_F("cmd.mem")
) cmd_rom (
	.addr(cmd_rom_addr),
	.data(cmd_rom_data)
);

logic [3:0] flags;
logic [27:0] delay_usec;
logic [7:0] str_len;

always @(posedge CLK) begin
	if (!rst_n) begin
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
				wait_counter <= 0;
				wait_limit <= ONE_USEC * 50 * 1000;
				cmd_state <= C_FLAGS;
				sm_state <= S_PROC_EXEC_CMD;
				next_sm_state <= S_AFTER_INIT;
				cmd_rom_addr <= `CmdInitAndWelcome;
			end

			S_PROC_EXEC_CMD: begin
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
				lfsr_seed <= lfsr_seed + 1;
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						attempt_count = 1;
						lfsr_seed_set <= 1;
						lfsr_en <= 1;
						wait_counter <= 0;
						wait_limit <= ONE_USEC * 50 * 1000;
						cmd_state <= C_FLAGS;
						sm_state <= S_PROC_EXEC_CMD;
						next_sm_state <= S_CONVERT_ATTEMPT;
						cmd_rom_addr <= `CmdShowAttemptPrompt;
					end
				end
			end

			S_CONVERT_ATTEMPT: begin
				lfsr_en <= 0;
				bcd_en <= 1;
				sm_state <= S_OUTPUT_ATTEMPT;
				output_buf <= {OUTPUT_WIDTH{"0"}};
			end

			S_OUTPUT_ATTEMPT: begin
				bcd_en <= 0;
				if (bcd_ready) begin
					debug <= ~debug;
					integer i;
					for (i = 0; i < 2; i = i + 1) begin
						output_buf[(2 - i) * 8 - 1 -: 8] <= {4'h3, bcd_out[i * 4 + 4 - 1 -: 4]};
					end
					next_sm_state <= S_CLEAR_INPUT;
					sm_state <= S_PROC_PRINT_OUTPUT_BUF;
					char_index <= 0;
					char_count <= 2;
				end
			end

			S_CLEAR_INPUT: begin
				output_buf <= {OUTPUT_WIDTH{"0"}};
				sm_state <= S_NUM_INPUT;
			end

			S_NUM_INPUT: begin
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						sm_state <= S_CHECK_GUESS;
					end
					else begin
						case (IR_DATA)
							`KEY_0: output_buf[0:31] <= {output_buf[8:31], "0"};
							`KEY_1: output_buf[0:31] <= {output_buf[8:31], "1"};
							`KEY_2: output_buf[0:31] <= {output_buf[8:31], "2"};
							`KEY_3: output_buf[0:31] <= {output_buf[8:31], "3"};
							`KEY_4: output_buf[0:31] <= {output_buf[8:31], "4"};
							`KEY_5: output_buf[0:31] <= {output_buf[8:31], "5"};
							`KEY_6: output_buf[0:31] <= {output_buf[8:31], "6"};
							`KEY_7: output_buf[0:31] <= {output_buf[8:31], "7"};
							`KEY_8: output_buf[0:31] <= {output_buf[8:31], "8"};
							`KEY_9: output_buf[0:31] <= {output_buf[8:31], "9"};
							default: output_buf <= output_buf;
						endcase
						wait_counter <= 0;
						wait_limit <= ONE_USEC * 50 * 1000;
						cmd_state <= C_FLAGS;
						sm_state <= S_PROC_EXEC_CMD;
						next_sm_state <= S_SHOW_USER_INPUT;
						cmd_rom_addr <= `CmdMoveToNumInput;
					end
				end
				else
					char_count <= 0;
			end

			S_SHOW_USER_INPUT: begin
				user_number <=  (output_buf[0:7] - "0") * 1000 +
								(output_buf[8:15] - "0")  * 100 +
								(output_buf[16:23] - "0")  * 10 +
								(output_buf[24:31] - "0");
				next_sm_state <= S_NUM_INPUT;
				sm_state <= S_PROC_PRINT_OUTPUT_BUF;
				char_index <= 0;
				char_count <= 4;
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
				next_sm_state <= S_AFTER_CHECK;
				if (goal_number < user_number)
					cmd_rom_addr <= `CmdSayLesser;
				else if (goal_number > user_number)
					cmd_rom_addr <= `CmdSayGreater;
				else begin
					cmd_rom_addr <= `CmdSayVictory;
					next_sm_state <= S_AFTER_VICTORY;
				end
				wait_counter <= 0;
				wait_limit <= ONE_USEC * 50 * 1000;
				cmd_state <= C_FLAGS;
				sm_state <= S_PROC_EXEC_CMD;
			end

			S_AFTER_CHECK: begin
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						attempt_count = attempt_count + 1;
						wait_counter <= 0;
						wait_limit <= ONE_USEC * 50 * 1000;
						cmd_state <= C_FLAGS;
						sm_state <= S_PROC_EXEC_CMD;
						next_sm_state <= S_CONVERT_ATTEMPT;
						cmd_rom_addr <= `CmdShowAttemptPrompt;
					end
				end
			end
			
			S_AFTER_VICTORY: begin
				if (IR_DATA_READY) begin
					if (IR_DATA == `KEY_OK) begin
						wait_counter <= 0;
						wait_limit <= ONE_USEC * 50 * 1000;
						cmd_state <= C_FLAGS;
						cmd_rom_addr <= `CmdShowGameTitle;
						sm_state <= S_PROC_EXEC_CMD;
						next_sm_state <= S_AFTER_INIT;
					end
				end
			end

			default:
				sm_state <= S_IDLE;
		endcase
	end
end

logic _unused_ok = &{1'b1, enable, mosi_data, miso_data, BTN1, busy, 1'b0};

endmodule
