`default_nettype none
`timescale 1ns / 1ps

module top_mk14
(
	input wire logic CLK,
	input wire logic BTN1,
	input wire logic BTN2,
	input wire logic BTN3,
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

//assign LED = ~trace;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

logic [8 * 8 - 1:0] display;

//assign LED[0] = |display[0 * 8 + 7 -: 8];
//assign LED[1] = |display[1 * 8 + 7 -: 8];
//assign LED[2] = |display[2 * 8 + 7 -: 8];
//assign LED[3] = |display[3 * 8 + 7 -: 8];
//assign LED[4] = |display[4 * 8 + 7 -: 8];
//assign LED[5] = |display[5 * 8 + 7 -: 8];
//assign LED[6] = |display[6 * 8 + 7 -: 8];
//assign LED[7] = |display[7 * 8 + 7 -: 8];

assign LED = ~trace;

mk14_soc #(
	.CLOCK_FREQ_MHZ(12),
	.INIT_F("../programs/multiply.mem")
)
mk14_soc_inst (
	.rst_n,
	.clk(CLK),
	.trace,
	.display
);

endmodule
