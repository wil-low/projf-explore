// LED&KEY memory mapped IO 

`default_nettype none
`timescale 1ns / 1ps

module tm1638_led_key_memmap
#(
	parameter CLOCK_FREQ_MHz = 12,
	parameter SEG7_BASE_ADDR = 'h0100,
	parameter LED_BASE_ADDR  = 0
)
(
	input wire i_clk,
	input wire i_en,					// enable

	output logic o_read_en,
	output logic [15:0] o_read_addr, 
	input wire [7:0] i_read_data, 
	
	// shield pins
	output logic o_tm1638_clk,
	output logic o_tm1638_stb,
	inout  wire io_tm1638_data,

	output logic probe,
	output logic o_idle
);

localparam BATCH_DATA_SIZE = 17;

logic batch_en = 0;
logic [8 * BATCH_DATA_SIZE - 1 : 0] batch_data;

logic cmd_en = 0;
logic [7 : 0] data;

logic ledkey_idle;

tm1638_led_key
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
)
tm1638_led_key_inst
(
	.i_clk(i_clk),
	.i_cmd_en(cmd_en),					// enable sending raw data
	.i_seg7_en(0),						// enable setting one seg7's state
	.i_led_en(0),						// enable setting one LED state
	.i_all_led_en(0),					// enable setting all LED states at once
	.i_batch_en(batch_en),				// enable sending up to 17 bytes of batch_data
	.i_btn_en(0),						// enable reading buttons' state

	.i_idx(),							// seg7/led index (0-7)

	.i_data(data),						// byte to send
	.o_btn_state(),						// button0-7 state (1 = pressed) 

	.i_batch_data_size(BATCH_DATA_SIZE),
	.i_batch_data(batch_data),
	.i_wait_counter(1),

	// shield pins
	.o_tm1638_clk(o_tm1638_clk),
	.o_tm1638_stb(o_tm1638_stb),
	.io_tm1638_data(io_tm1638_data),

	.o_probe(),
	.o_idle(ledkey_idle)
);

enum {
	s_RESET, s_RESET1, s_RESET2, s_IDLE,
	s_FETCH_LED, s_WAIT_MEM_LED, s_SAVE_LED,
	s_FETCH, s_WAIT_MEM, s_FILL_BATCH, s_SEND_DATA,
	s_WAIT
} state;

assign o_idle = (state == s_IDLE) && ledkey_idle;

assign probe = ledkey_idle;

logic [7:0] saved_led;

logic [3:0] data_counter;

always @(posedge i_clk) begin
	batch_en <= 0;
	cmd_en <= 0;
	o_read_en <= 0;

	case (state)

	s_RESET: if (ledkey_idle) begin
		data <= 8'h40;  // set auto increment mode
		cmd_en <= 1;
		state <= s_RESET1;
	end

	s_RESET1: if (ledkey_idle) begin
		batch_data <= {8'hc0, {16{8'h00}}};
		batch_en <= 1;
		state <= s_RESET2;
	end

	s_RESET2: if (ledkey_idle) begin
		data <= 8'h88;  // activate
		cmd_en <= 1;
		state <= s_IDLE;
	end

	s_IDLE: if (ledkey_idle) begin
		if (i_en) begin
			data_counter <= 0;
			state <= s_FETCH_LED;
		end
	end

	s_FETCH_LED: begin
		o_read_en <= 1;
		o_read_addr <= LED_BASE_ADDR;
		state <= s_WAIT_MEM_LED;
	end

	s_WAIT_MEM_LED: begin
		state <= s_SAVE_LED;
	end

	s_SAVE_LED: begin
		saved_led <= i_read_data;
		state <= s_FETCH;
	end

	s_FETCH: begin
		o_read_en <= 1;
		o_read_addr <= SEG7_BASE_ADDR + data_counter;
		state <= s_WAIT_MEM;
	end

	s_WAIT_MEM: begin
		state <= s_FILL_BATCH;
	end

	s_FILL_BATCH: begin
		data_counter <= data_counter + 1;
		batch_data[8 * (data_counter * 2 + 1) + 7 -: 8] <= i_read_data;
		batch_data[8 * (data_counter * 2 + 0) + 7 -: 8] <= saved_led[data_counter];
		state <= (data_counter == 8) ? s_SEND_DATA : s_FETCH;
	end

	s_SEND_DATA: begin
		batch_en <= 1;
		state <= s_IDLE;
	end

	default: begin
		state <= s_RESET;
	end

	endcase
end

endmodule
