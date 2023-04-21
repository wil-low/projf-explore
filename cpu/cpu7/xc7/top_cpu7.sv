`default_nettype none
`timescale 1ns / 1ps

module top_cpu7
(
	input logic CLK,
	input logic rst_n,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4
);

logic [7:0] trace;

assign {LED1, LED2, LED3, LED4} = trace;

cpu7_soc #(
    .CLOCK_FREQ_MHZ(50),
    .CORES(1),
    .PROGRAM_SIZE(1024),
    .VREGS(8),
    .DATA_STACK_DEPTH(8),
    .CALL_STACK_DEPTH(8),
    .USE_MUL(1),
    .MUL_DATA_WIDTH(56),
    .USE_DIV(1),
    .DIV_DATA_WIDTH(56),
    .INIT_F("collatz.mem")
)
cpu7_soc_inst (
	.rst_n,
	.clk(CLK),
	.trace(trace)
);

logic _unused_ok = &{1'b1, 1'b0};

endmodule
