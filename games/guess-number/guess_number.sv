`default_nettype none
`timescale 1ns / 1ps

module guess_number
(
	input CLK,
	input BTN1,

	inout SCL,
	inout SDA,

	output [7:0] LED,
	output LED1
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

assign LED = ~mosi_data;
assign LED1 = ~busy;

//logic dmode_up;
/* verilator lint_off PINCONNECTEMPTY */
//debouncer dmode (.i_Clock(CLK), .i_Button(BTN1), .o_ButtonState(), .o_DownEvent(), .o_UpEvent(dmode_up));
/* verilator lint_on PINCONNECTEMPTY */

localparam ONE_USEC = 12; // CLK / 1M

logic [24:0] wait_counter;
logic [24:0] wait_limit;

logic [4:0] substate;

enum {S_IDLE, S_PREINIT, S_INIT, S_PRINT} sm_state;

/* verilator lint_off LITENDIAN */
logic [0 : 15 * 8 - 1] message0 = "Guess a number:";
/* verilator lint_on LITENDIAN */

always @(posedge CLK) begin
	if (!rst_n) begin
		mosi_data <= 8'h0f;
		sm_state <= S_PREINIT;
	end
	else begin
		if (busy)
			enable <= 0;
		case (sm_state)
			S_IDLE: begin
				/*if (dmode_up && !busy) begin
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 50 * 1000;
					substate <= 0;
					sm_state <= S_INIT;
				end*/
			end

			S_PREINIT: begin
				wait_counter <= 0;
				wait_limit <= ONE_USEC * 50 * 1000;
				substate <= 0;
				sm_state <= S_INIT;
			end

			S_INIT: begin
				if (!busy) begin
					wait_counter <= wait_counter + 1;
					if (wait_counter == wait_limit) begin
						wait_counter <= 0;
						case (substate)
							0: begin
								enable <= 1;
								with_pulse <= 0;
								send_2nd_nibble <= 1;
								backlight <= 0;
								mosi_data <= 8'h00; // reset expander and turn backlight off
								wait_limit <= ONE_USEC * 1000 * 1000;
								substate <= substate + 1;
							end
							1: begin
								enable <= 1;
								with_pulse <= 1;
								send_2nd_nibble <= 0;
								mosi_data <= 8'h30; // we start in 8bit mode, try to set 4 bit mode
								wait_limit <= ONE_USEC * 4500;
								substate <= substate + 1;
							end
							2: begin
								enable <= 1;
								mosi_data <= 8'h30; // second try
								wait_limit <= ONE_USEC * 4500;
								substate <= substate + 1;
							end
							3: begin
								enable <= 1;
								mosi_data <= 8'h30; // third go!
								wait_limit <= ONE_USEC * 150;
								substate <= substate + 1;
							end
							4: begin
								enable <= 1;
								mosi_data <= 8'h20; // finally, set to 4-bit interface
								wait_limit <= ONE_USEC * 150;
								substate <= substate + 1;
							end
							5: begin
								enable <= 1;
								send_2nd_nibble <= 1;
								mosi_data <= 8'h28; // set # lines, font size, etc.
								wait_limit <= ONE_USEC * 10;
								substate <= substate + 1;
							end
							6: begin
								enable <= 1;
								mosi_data <= 8'h0c; // turn the display on with no cursor or blinking default
								wait_limit <= ONE_USEC * 10;
								substate <= substate + 1;
							end
							7: begin
								enable <= 1;
								mosi_data <= 8'h01; // clear it off
								wait_limit <= ONE_USEC * 2000;
								substate <= substate + 1;
							end
							8: begin
								enable <= 1;
								mosi_data <= 8'h06; // // set the entry mode
								wait_limit <= ONE_USEC * 2000;
								substate <= substate + 1;
							end
							9: begin
								enable <= 1;
								mosi_data <= 8'h02; // return home
								wait_limit <= ONE_USEC * 2000;
								substate <= substate + 1;
							end
							10: begin
								enable <= 1;
								backlight <= 1;
								with_pulse <= 0;
								send_2nd_nibble <= 1;
								mosi_data <= 8'h00; // backlight
								wait_limit <= ONE_USEC * 10;
								substate <= 0;
								sm_state <= S_PRINT;
							end
							11: begin
								enable <= 1;
								with_pulse <= 1;
								send_2nd_nibble <= 0;
								mosi_data <= 8'h80; // setCursor
								wait_limit <= ONE_USEC * 10;
								substate <= 0;
								sm_state <= S_PRINT;
							end
						endcase
					end
				end
			end

			S_PRINT: begin
				if (!busy) begin
					wait_counter <= wait_counter + 1;
					if (wait_counter == wait_limit) begin
						wait_counter <= 0;
						enable <= 1;
						with_pulse <= 1;
						send_2nd_nibble <= 1;
						data_mode <= 1;
						mosi_data <= message0[substate * 8 +: 8];
						wait_limit <= ONE_USEC * 1000 * 100;
						substate <= substate + 1;
						if (substate == 14)
							sm_state <= S_IDLE;
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
