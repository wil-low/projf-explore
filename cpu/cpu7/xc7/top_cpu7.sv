`default_nettype none
`timescale 1ns / 1ps

module top_cpu7
(
	input logic CLK,
	input logic rst_n,
	input logic BTN1,
	input logic BTN2,
	input logic BTN3,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4
);

logic [7:0] trace;

assign LED = ~trace;

cpu7_soc #(.CORES(4), .INIT_F("../test.mem"))
	cpu7_soc_inst (.rst_n, .clk(CLK), .trace(trace));

logic _unused_ok = &{1'b1, 1'b0};

endmodule
