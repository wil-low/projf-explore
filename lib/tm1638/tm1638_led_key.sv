// High-level LED&KEY shield driver 

`default_nettype none
`timescale 1ns / 1ps

module tm1638_led_key
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
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
logic tm1638_idle;

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
	.i_raw_data(i_raw_data),
	.o_tm1638_clk(o_tm1638_clk),
	.o_tm1638_stb(o_tm1638_stb),
	.io_tm1638_data(io_tm1638_data),
	.o_idle(tm1638_idle)
);

wire _unused_ok = &{1'b1, i_en_raw, i_en_led, i_led_state, i_en_seg7, i_seg7_idx, i_seg7_state, i_en_buttons, 1'b0};

endmodule
