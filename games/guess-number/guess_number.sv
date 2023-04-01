`default_nettype none
`timescale 1ns / 1ps

module guess_number
(
	input CLK,
	input BTN1,

	inout SCL,
	inout SDA,

	output [7:0] LED,
	output LED1,
	output LED2
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

assign LED = debug ? ~{4'b0, flags} : ~cmd_rom_addr;
assign LED1 = ~busy;
assign LED2 = ~debug;

//logic dmode_up;
/* verilator lint_off PINCONNECTEMPTY */
//debouncer dmode (.i_Clock(CLK), .i_Button(BTN1), .o_ButtonState(), .o_DownEvent(), .o_UpEvent(dmode_up));
/* verilator lint_on PINCONNECTEMPTY */

localparam ONE_USEC = 12; // CLK / 1M

logic [28:0] wait_counter;
logic [28:0] wait_limit;

enum {S_IDLE, S_PREINIT, S_INIT, S_PRINT} sm_state;
enum {C_FLAGS, C_DELAY1, C_DELAY2, C_DELAY3, C_DATA, C_CHAR} cmd_state;

logic [7:0] cmd_rom_addr;
logic [7:0] cmd_rom_data;

`include "cmd_flags.svh"

rom_async #(
	.WIDTH(8),
	.DEPTH(200),
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
		mosi_data <= 8'h0f;
		sm_state <= S_PREINIT;
		cmd_rom_addr <= 0;
	end
	else begin
		if (busy)
			enable <= 0;
		case (sm_state)
			S_IDLE: begin
				/*if (dmode_up && !busy) begin
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 50 * 1000;
					cmd_state <= 0;
					sm_state <= S_INIT;
				end*/
			end

			S_PREINIT: begin
				wait_counter <= 0;
				wait_limit <= ONE_USEC * 50 * 1000;
				cmd_state <= C_FLAGS;
				sm_state <= S_INIT;
			end

			S_INIT: begin
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
										sm_state <= cmd_rom_data;  // goto next sm_state
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

			default:
				sm_state <= S_IDLE;
		endcase
	end
end

logic _unused_ok = &{1'b1, enable, mosi_data, miso_data, BTN1, busy, 1'b0};

endmodule
