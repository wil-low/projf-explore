`default_nettype none
`timescale 1ns / 1ps

module seg7_dig
(
	input [3:0] i_Digit,
	output [7:0] o_Cathodes
);

logic [7:0] cathode;

always @* begin
	case (i_Digit)
		4'h0: cathode = 8'b00000011;
		4'h1: cathode = 8'b10011111;
		4'h2: cathode = 8'b00100101;
		4'h3: cathode = 8'b00001101;
		4'h4: cathode = 8'b10011001;
		4'h5: cathode = 8'b01001001;
		4'h6: cathode = 8'b01000001;
		4'h7: cathode = 8'b00011111;
		4'h8: cathode = 8'b00000001;
		4'h9: cathode = 8'b00001001;
		4'ha: cathode = 8'b00010001;
		4'hb: cathode = 8'b11000001;
		4'hc: cathode = 8'b01100011;
		4'hd: cathode = 8'b10000101;
		4'he: cathode = 8'b01100001;
		4'hf: cathode = 8'b01110001;
	endcase
	$display("data2: %s", i_Digit);
end

assign o_Cathodes = cathode;

endmodule
