`default_nettype none
`timescale 1ns / 1ps

module top_guess_number (
	input CLK,
	input BTN1,
	input IR,

	inout SCL,
	inout SDA,

	output [7:0] LED,
	output LED1,
	output LED2,
	output LED4
	);

	guess_number #(12) guess_number_inst(.CLK, .BTN1, .IR_DATA(ir_data[15:8]), .IR_DATA_READY(data_ready), .SCL, .SDA, .LED, .LED1, .LED2);

	logic data_ready;
	logic idle;

	assign LED4 = IR;

	reg [4 * 8 - 1:0] ir_data;

	wire [7:0] error_code;

	infrared_rx rx (CLK, IR, ir_data, idle, data_ready, error_code);

endmodule
