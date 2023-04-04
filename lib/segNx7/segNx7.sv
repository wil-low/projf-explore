//---------------------------------------------------------
//-- segNx7.v  
//-- N x Seven Segment Indicator Driver
//---------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module segNx7
#(
	parameter DIGITS = 4,
	parameter ONLY_DIGITS = 1'b1,
	parameter SWITCH_SPEED = 7,  // set this to 17+ for visible segment switching; do not set 5- due to SM
	parameter INVERT_ANODES = 1'b0	
)
(   
	input i_Clock,
	input [DIGITS * (ONLY_DIGITS ? 4 : 8) - 1:0] i_Data,
	input i_Idle,
	output reg o_Start,
	output reg [DIGITS - 1:0] o_Anodes,
	output reg [7:0] o_Cathodes
);

logic [SWITCH_SPEED + 1:0] counter = 0;
wire [DIGITS * 8 - 1:0] segments;

`define NUM counter[SWITCH_SPEED + 1: SWITCH_SPEED]

generate
	genvar i;
	for (i = 0; i < DIGITS; i = i + 1) begin: indicators
	if (ONLY_DIGITS)
		seg7_dig s(i_Data[i * 4 + 3 -: 4], segments[i * 8 + 7 -: 8]);
	else
		seg7_sym s(i_Data[i * 8 + 7 -: 8], segments[i * 8 + 7 -: 8]);
	end
endgenerate

always @(posedge i_Clock) begin
	//$display("number %d, o_Anodes %b, pins %b", `NUM, o_Anodes, o_Cathodes);
	if (i_Idle) begin
		o_Start <= 1;
		o_Anodes <= INVERT_ANODES ? ~(1 << `NUM) : (1 << `NUM);
		o_Cathodes <= segments[`NUM * 8 + 7 -: 8];
	end
	counter <= counter + 1;
end

endmodule
