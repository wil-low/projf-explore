`default_nettype none
`timescale 1ns / 1ps

module top_ladder
(
	input CLK, input BTN,
	output AN1, output AN2, output AN3, output AN4,
	output CA, output CB, output CC, output CD, output CE, output CF, output CG, output DP,
	output LED0, output LED1, output LED2, output LED3, output LED4, output LED5, output LED6, output LED7
);

localparam digits = 4;

logic start;

logic btn_up, btn_dn;

/* verilator lint_off PINCONNECTEMPTY */
debounce debounce_inst (
	.clk(CLK),
	.in(BTN),
	.out(),
	.ondn(btn_dn),
	.onup(btn_up)
);

logic [digits * 8 - 1:0] message;

segNx7
#(
	.DIGITS(digits), .ONLY_DIGITS(0)
) segNx7_inst (
	CLK, message, 1'b1, start,
	{AN1, AN2, AN3, AN4},
	{CA, CB, CC, CD, CE, CF, CG, DP}
);

ladder ladder_inst (
	CLK,
	btn_dn,
	{LED0, LED1, LED2, LED3, LED4, LED5, LED6, LED7},
	message
);

logic _unused_ok = &{1'b1, btn_up, start, 1'b0};

endmodule
