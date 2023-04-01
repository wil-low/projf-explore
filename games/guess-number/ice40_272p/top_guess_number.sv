`default_nettype none
`timescale 1ns / 1ps

module top_guess_number (
	input CLK,
	input BTN1,

	inout SCL,
	inout SDA,

	output [7:0] LED,
	output LED1,
	output LED2
	);

	guess_number guess_number_inst(.CLK, .BTN1, .SCL, .SDA, .LED, .LED1, .LED2);

endmodule
