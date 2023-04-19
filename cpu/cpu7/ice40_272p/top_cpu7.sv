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

logic [11:0] trace;

assign {LED1, LED2, LED3, LED4, LED}  = ~trace;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

cpu7_soc #(
	.CLOCK_FREQ_MHZ(12),
	.CORES(1),
	.PROGRAM_SIZE(128),
	.DATA_STACK_DEPTH(8),
	.CALL_STACK_DEPTH(8),
	.VREGS(8),
	.MUL_DIV_DATA_WIDTH(28),
	.INIT_F("../test.mem")
)
cpu7_soc_inst (
	.rst_n,
	.clk(CLK),
	.trace(trace)
);

logic _unused_ok = &{1'b1, 1'b0};

endmodule
