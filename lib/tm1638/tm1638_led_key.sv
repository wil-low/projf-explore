// High-level LED&KEY shield driver 

`default_nettype none
`timescale 1ns / 1ps

module tm1638_led_key
#(
	parameter CLOCK_FREQ_MHz = 12,
	parameter WAIT_USEC = 512
)
(
	input wire i_clk,
	input wire rst_n,					// perform startup init sequence
	input wire i_en_raw,				// enable sending raw data
	input wire [7:0] i_raw_data,		// raw data to send (e.g. for init or custom commands)

	input wire i_en_led,				// enable setting LED state
	input wire [7:0] i_led_state,		// LED1-8 state (1 = lit)

	input wire i_en_seg7,				// enable setting one seg7's state
	input wire [2:0] i_seg7_idx,		// seg7 index (0-7)
	input wire [7:0] i_seg7_state,		// seg7 state (1 = lit)

	input wire i_en_buttons,			// enable reading buttons' state
	output logic [7:0] o_button_state,	// button1-8 state (1 = pressed) 

	// shield pins
	output logic o_tm1638_clk,
	output logic o_tm1638_stb,
	inout  wire io_tm1638_data,

	// results
	output logic o_idle
);

logic tm1638_en = 0;
logic [7:0] raw_data;
logic tm1638_idle;

logic [5:0] data_size;
logic [5:0] data_counter;
/* verilator lint_off LITENDIAN */
logic [0:8 * 17 - 1] data;
/* verilator lint_on LITENDIAN */

assign o_button_state = 0;
assign o_idle = tm1638_idle;

tm1638
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
)
tm1638_inst
(
	.i_clk(i_clk),
	.i_en(tm1638_en),
	.i_raw_data(raw_data),
	.o_tm1638_clk(o_tm1638_clk),
	.io_tm1638_data(io_tm1638_data),
	.o_idle(tm1638_idle)
);

enum {
	s_IDLE, s_RESET, s_INIT_STEP, s_SEND_DATA, s_DELAY
} state, next_state;

logic [3:0] state_counter;

localparam ONE_USEC = CLOCK_FREQ_MHz;
logic [15:0] wait_counter;

always @(posedge i_clk) begin
	tm1638_en <= 0;
	if (!rst_n) begin
		state <= s_RESET;
		o_tm1638_stb <= 1;
		$display($time, "RESET");
	end
	else begin
		case (state)

		s_RESET: begin
			state <= s_INIT_STEP;
			state_counter <= 8;
		end

		s_INIT_STEP: begin
			next_state <= s_INIT_STEP;
			if (tm1638_idle) begin
				if (state_counter == 0)
					state <= s_IDLE;
				case (state_counter)
				8: begin
					o_tm1638_stb <= 0;
					data_size <= 1;
					data_counter <= 0;
					data[0:7] <= 8'h8f; // activate
					state <= s_SEND_DATA;
				end
				7: begin
					o_tm1638_stb <= 1;
					wait_counter <= ONE_USEC * WAIT_USEC;
					state <= s_DELAY;
				end
				6: begin
					o_tm1638_stb <= 0;
					data_size <= 1;
					data_counter <= 0;
					data[0:7] <= 8'h40; // set auto increment mode
					state <= s_SEND_DATA;
				end
				5: begin
					o_tm1638_stb <= 1;
					wait_counter <= ONE_USEC * WAIT_USEC;
					state <= s_DELAY;
				end
				4: begin
					o_tm1638_stb <= 0;
					data_size <= 17;
					data_counter <= 0;
					data <= {8'hc0, 128'h0}; // set starting address to 0, then send 16 zero bytes
					state <= s_SEND_DATA;
				end
				3: begin
					o_tm1638_stb <= 1;
					wait_counter <= ONE_USEC * WAIT_USEC;
					state <= s_DELAY;
				end
				2: begin
					o_tm1638_stb <= 0;
					data_size <= 17;
					data_counter <= 0;
					data <= {8'hc0, 8'h3f, 8'h00, 8'h06, 8'h00, 8'h5b, 8'h00, 8'h4f, 8'h00, 8'h66, 8'h00, 8'h6d, 8'h00, 8'h7d, 8'h00, 8'h07, 8'h00};
					//data <= {8'hc0, 128'h0}; // set starting address to 0, then send 16 zero bytes
					state <= s_SEND_DATA;
				end
				1: begin
					o_tm1638_stb <= 1;
					wait_counter <= ONE_USEC * WAIT_USEC;
					state <= s_DELAY;
				end
				default:
					state <= s_IDLE;
				endcase
				state_counter <= state_counter - 1;
			end
		end

		s_IDLE: begin
			//$display("IDLE");
		end

		s_DELAY: begin
			if (wait_counter == 0)
				state <= next_state;
			wait_counter <= wait_counter - 1;
		end

		s_SEND_DATA: begin
			if (tm1638_idle) begin
				if (data_counter == data_size)
					state <= next_state;
				else begin
					tm1638_en <= 1;
					raw_data <= data[data_counter * 8 +: 8];
					data_counter <= data_counter + 1;
				end
			end
		end

		default:
			state <= s_IDLE;

		endcase
	end
end

wire _unused_ok = &{1'b1, i_en_raw, i_en_led, i_led_state, i_en_seg7, i_seg7_idx, i_seg7_state, i_en_buttons, i_raw_data, 1'b0};

endmodule
