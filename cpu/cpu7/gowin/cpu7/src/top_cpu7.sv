`default_nettype none
`timescale 1ns / 1ps

module top_cpu7
(
	input wire logic CLK,
	input wire logic rst_n,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4
);

logic [11:0] trace;

assign {LED1, LED2, LED3, LED4} = trace[11:8];
assign LED  = ~trace[7:0];

cpu7_soc #(
    .CLOCK_FREQ_MHZ(27),
	.CORES(1),
	.PROGRAM_SIZE(256),
	.DATA_STACK_DEPTH(8),
	.CALL_STACK_DEPTH(8),
	.VREGS(2),
	.USE_MUL(1),
	.MUL_DATA_WIDTH(28),
	.USE_DIV(1),
	.DIV_DATA_WIDTH(28),
    .INIT_F("../collatz.mem")
)
cpu7_soc_inst (
	.rst_n,
	.clk(CLK),
	.trace(trace)
);

logic _unused_ok = &{1'b1, 1'b0};

endmodule
