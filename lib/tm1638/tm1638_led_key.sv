// High-level LED&KEY shield driver 

`default_nettype none
`timescale 1ns / 1ps

module tm1638_led_key
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
	input wire i_cmd_en,				// enable sending a command
	input wire i_seg7_en,				// enable setting one seg7's state
	input wire i_led_en,				// enable setting one LED state
	input wire i_all_led_en,			// enable setting all LED states at once
	input wire i_batch_en,				// enable sending up to 17 bytes of batch_data
	input wire i_btn_en,				// enable reading buttons' state

	input wire [2:0] i_idx,				// seg7/led index (0-7)

	input wire [7:0] i_data,			// byte to send
	output logic [7:0] o_btn_state,		// button0-7 state (1 = pressed) 

	input wire [4:0] i_batch_data_size,
	input wire [8 * 17 - 1 : 0] i_batch_data,
	input wire [27:0] i_wait_counter,
	
	// shield pins
	output logic o_tm1638_clk,
	output logic o_tm1638_stb,
	inout  wire io_tm1638_data,

	// results
	output logic o_probe,
	output logic o_idle
);

logic tm1638_write_en = 0;
logic tm1638_read_en = 0;
logic [7:0] raw_data;
logic tm1638_idle;

logic [4:0] data_counter;
/* verilator lint_off LITENDIAN */
logic [8 * 17 - 1 : 0] data;
/* verilator lint_on LITENDIAN */

tm1638
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
)
tm1638_inst
(
	.i_clk(i_clk),
	.i_write_en(tm1638_write_en),
	.i_raw_data(raw_data),
	.i_read_en(tm1638_read_en),
	.o_btn_state(o_btn_state),
	.o_tm1638_clk(o_tm1638_clk),
	.io_tm1638_data(io_tm1638_data),
	.o_probe(o_probe),
	.o_idle(tm1638_idle)
);

enum {
	s_IDLE, s_INIT_STEP, s_SEND_DATA, s_SEND_CMD, s_SET_ALL_LED, s_SET_ALL_LED_STEP, s_READ_BTN, s_READ_BTN_DONE, s_DELAY
} state, next_state;

assign o_idle = (state == s_IDLE) && tm1638_idle && !i_cmd_en && !i_seg7_en && !i_led_en && !i_batch_en && !i_btn_en && !i_all_led_en;

logic [3:0] state_counter;

logic [27:0] wait_counter;

always @(posedge i_clk) begin
	tm1638_write_en <= 0;
	tm1638_read_en <= 0;

	case (state)

	s_IDLE: begin
		o_tm1638_stb <= 1;
		next_state <= s_DELAY;
		if (i_cmd_en) begin
			o_tm1638_stb <= 0;
			raw_data <= i_data;
			wait_counter <= i_wait_counter;
			tm1638_write_en <= 1;
			state <= s_SEND_CMD;
		end
		else if (i_batch_en) begin
			o_tm1638_stb <= 0;
			data_counter <= i_batch_data_size;
			data <= i_batch_data;
			wait_counter <= i_wait_counter;
			state <= s_SEND_DATA;
		end
		else if (i_seg7_en) begin
			o_tm1638_stb <= 0;
			data_counter <= 2;
			data <= {8'hc0 + (i_idx << 1), i_data};
			wait_counter <= i_wait_counter;
			state <= s_SEND_DATA;
		end
		else if (i_led_en) begin
			o_tm1638_stb <= 0;
			data_counter <= 2;
			data <= {8'hc1 + (i_idx << 1), i_data};
			wait_counter <= i_wait_counter;
			state <= s_SEND_DATA;
		end
		else if (i_all_led_en) begin
			state_counter <= 0;
			data[23:8] <= {i_data, 8'hbf};  // c1 - 02
			state <= s_SET_ALL_LED;
			wait_counter <= i_wait_counter;
		end
		else if (i_btn_en) begin
			o_tm1638_stb <= 0;
			raw_data <= 8'h42;
			wait_counter <= 0;
			tm1638_write_en <= 1;
			state <= s_SEND_CMD;
			next_state <= s_READ_BTN;
		end
	end

	s_DELAY: begin
		if (wait_counter == 0) begin
			o_tm1638_stb <= 1;
			state <= s_IDLE;
		end
		wait_counter <= wait_counter - 1;
	end

	s_SEND_CMD: begin
		if (tm1638_idle) begin
			state <= next_state;
		end
	end

	s_SEND_DATA: begin
		if (tm1638_idle) begin
			if (data_counter == 0) begin
				state <= next_state;
			end
			else begin
				tm1638_write_en <= 1;
				raw_data <= data[data_counter * 8 - 1 -: 8];
				data_counter <= data_counter - 1;
			end
		end
	end

	s_SET_ALL_LED: begin
		if (tm1638_idle) begin
			if (state_counter == 8) begin
				state <= s_DELAY;
			end
			else begin
				o_tm1638_stb <= 0;
				data_counter <= 2;
				data[15:8] <= data[15:8] + 2;
				data[7:0] <= data[16 + state_counter];
				state <= s_SEND_DATA;
				next_state <= s_SET_ALL_LED_STEP;
				state_counter <= state_counter + 1;
			end
		end
	end

	s_SET_ALL_LED_STEP: begin
		o_tm1638_stb <= 1;
		state <= s_SET_ALL_LED;
	end

	s_READ_BTN: begin
		if (tm1638_idle) begin
			tm1638_read_en <= 1;
			state <= s_READ_BTN_DONE;
		end
	end

	s_READ_BTN_DONE: begin
		if (tm1638_idle) begin
			next_state <= s_IDLE;
			$display("%t o_btn_state_lk %b", $time, o_btn_state);
			state <= s_DELAY;
		end
	end

	default:
		state <= s_IDLE;

	endcase
end

wire _unused_ok = &{1'b1, 1'b0};

endmodule
