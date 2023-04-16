`default_nettype none
`timescale 1ns / 1ps

module top_cpu7
(
	input logic CLK,
	input logic BTN1,
	input logic BTN2,
	input logic BTN3,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4
);

//// Reset emulation for ice40
logic [22:0] reset_counter = 0;
logic rst_n = &reset_counter;

logic [7:0] trace;

assign LED = ~trace;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

cpu7_soc #(.CORES(4), .INIT_F("../test.mem"))
	cpu7_soc_inst (.rst_n, .clk(CLK), .trace(trace));

logic _unused_ok = &{1'b1, 1'b0};

endmodule
