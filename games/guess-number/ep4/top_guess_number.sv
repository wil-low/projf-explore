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
	output LED3,
	output LED4
);

//// Reset emulation for ice40
logic [7:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

guess_number #(50)
	guess_number_inst(.CLK, .RST_N(rst_n), .BTN1, .IR_DATA(ir_data[15:8]), .IR_DATA_READY(ir_data_ready), .SCL, .SDA, .LED, .LED1, .LED2, .LED3);

logic ir_data_ready;
logic ir_idle;
reg [4 * 8 - 1:0] ir_data;
wire [7:0] ir_error_code;

infrared_rx rx (CLK, IR, ir_data, ir_idle, ir_data_ready, ir_error_code);

assign LED4 = IR;

endmodule
