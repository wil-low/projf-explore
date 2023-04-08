`default_nettype none
`timescale 1ns / 1ps

module top_guess_number (
	input logic CLK,
	input logic rst_n,
	input logic IR,

	inout wire SCL,
	inout wire SDA,

	//output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4
);

guess_number #(50)
	guess_number_inst(.CLK, .RST_N(rst_n), .IR_DATA(ir_data[15:8]), .IR_DATA_READY(ir_data_ready), .SCL, .SDA, .LED(), .LED1, .LED2, .LED3);

logic ir_data_ready;
logic ir_idle;
reg [4 * 8 - 1:0] ir_data;
wire [7:0] ir_error_code;

infrared_rx #(50) rx (CLK, IR, ir_data, ir_idle, ir_data_ready, ir_error_code);

assign LED4 = IR;

endmodule
