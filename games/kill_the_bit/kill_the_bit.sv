`default_nettype none
`timescale 1ns / 1ps

module kill_the_bit
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
	
	output logic o_ledkey_clk,
	output logic o_ledkey_stb,
	inout  wire  io_ledkey_dio,
	
	output logic [7:0] o_LED
);

logic en_raw = 0;
logic [7:0] raw_data = 0;
logic en_led = 0;
logic [7:0] led_state = 0;
logic en_seg7 = 0;
logic [2:0] seg7_idx = 0;
logic [7:0] seg7_state = 0;
logic en_buttons = 0;
logic [7:0] button_state;

logic ledkey_idle;

assign o_LED = 0;

tm1638_led_key
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
)
tm1638_led_key_inst
(
	.i_clk(i_clk),
	.i_en_raw(en_raw),				// enable sending raw data
	.i_raw_data(raw_data),			// raw data to send (e.g. for init or custom commands)

	.i_en_led(en_led),				// enable setting LED state
	.i_led_state(led_state),		// LED1-8 state (1 = lit)

	.i_en_seg7(en_seg7),			// enable setting one seg7's state
	.i_seg7_idx(seg7_idx),			// seg7 index (0-7)
	.i_seg7_state(seg7_state),		// seg7 state (1 = lit)

	.i_en_buttons(en_buttons),		// enable reading buttons' state
	.o_button_state(button_state),	// button1-8 state (1 = pressed) 

	// shield pins
	.o_tm1638_clk(o_ledkey_clk),
	.o_tm1638_stb(o_ledkey_stb),
	.io_tm1638_data(io_ledkey_dio),

	.o_idle(ledkey_idle)
);

logic _unused_ok = &{1'b1, button_state, ledkey_idle, 1'b0};

endmodule
