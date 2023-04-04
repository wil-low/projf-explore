`default_nettype none
`timescale 1ns / 1ps

module seg7_sym
(
	input [7:0] i_Symbol,
	output [7:0] o_Cathodes
);

logic [7:0] cathode;

always @* begin
	case (i_Symbol)
		"0", "o": cathode = 8'b00000011;
		"1", "i": cathode = 8'b10011111;
		"2": cathode = 8'b00100101;
		"3": cathode = 8'b00001101;
		"4": cathode = 8'b10011001;
		"5": cathode = 8'b01001001;
		"6": cathode = 8'b01000001;
		"7": cathode = 8'b00011111;
		"8": cathode = 8'b00000001;
		"9": cathode = 8'b00001001;
		"a": cathode = 8'b00010001;
		"b": cathode = 8'b11000001;
		"c": cathode = 8'b01100011;
		"d": cathode = 8'b10000101;
		"e": cathode = 8'b01100001;
		"f": cathode = 8'b01110001;

		"g": cathode = 8'b01000011;
		"h": cathode = 8'b10010001;
		"l": cathode = 8'b11100011;
		"p": cathode = 8'b00110001;
		"r": cathode = 8'b01110011;
		"s": cathode = 8'b01001001;
		"u": cathode = 8'b10000011;
		"y": cathode = 8'b10001001;

		"-": cathode = 8'b11111101;

		default: cathode = 8'b11111111;
	endcase
	$display("data2: %s", i_Symbol);
end

assign o_Cathodes = cathode;

endmodule
