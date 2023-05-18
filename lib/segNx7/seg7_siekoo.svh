`ifndef SIEKOO

`define SIEKOO

function [7:0] siekoo;
	input [7:0] c;
begin
	// https://fakoo.de/en/siekoo.html
	case (c)
	"0": siekoo = 8'b0011_1111;
	"1": siekoo = 8'b0000_0110;
	"2": siekoo = 8'b0101_1011;
	"3": siekoo = 8'b0100_1111;
	"4": siekoo = 8'b0110_0110;
	"5": siekoo = 8'b0110_1101;
	"6": siekoo = 8'b0111_1101;
	"7": siekoo = 8'b0000_0111;
	"8": siekoo = 8'b0111_1111;
	"9": siekoo = 8'b0110_1111;
	"a": siekoo = 8'b0101_1111;
	"b": siekoo = 8'b0111_1100;
	"c": siekoo = 8'b0101_1000;
	"d": siekoo = 8'b0101_1110;
	"e": siekoo = 8'b0111_1001;
	"f": siekoo = 8'b0111_0001;
	"g": siekoo = 8'b0011_1101;
	"h": siekoo = 8'b0111_0100;
	"i": siekoo = 8'b0001_0001;
	"j": siekoo = 8'b0000_1101;
	"k": siekoo = 8'b0111_0101;
	"l": siekoo = 8'b0011_1000;
	"m": siekoo = 8'b0101_0101;
	"n": siekoo = 8'b0101_0100;
	"o": siekoo = 8'b0101_1100;
	"p": siekoo = 8'b0111_0011;
	"q": siekoo = 8'b0110_0111;
	"r": siekoo = 8'b0101_0000;
	"s": siekoo = 8'b0010_1101;
	"t": siekoo = 8'b0111_1000;
	"u": siekoo = 8'b0001_1100;
	"v": siekoo = 8'b0010_1010;
	"w": siekoo = 8'b0110_1010;
	"x": siekoo = 8'b0001_0100;
	"y": siekoo = 8'b0110_1110;
	"z": siekoo = 8'b0001_1011;
	" ": siekoo = 8'b0000_0000;
	".": siekoo = 8'b0001_0000;
	",": siekoo = 8'b0000_1100;
	";": siekoo = 8'b0000_1010;
	":": siekoo = 8'b0000_1001;
	"=": siekoo = 8'b0100_1000;
	"+": siekoo = 8'b0100_0110;
	"/": siekoo = 8'b0101_0010;
	8'h5c:siekoo = 8'b0110_0100; // backslash
	"!": siekoo = 8'b0110_1011;
	"?": siekoo = 8'b0100_1011;
	"_": siekoo = 8'b0000_1000;
	"-": siekoo = 8'b0100_0000;
	"^": siekoo = 8'b0000_0001;
	"'": siekoo = 8'b0010_0000;
	"\"":siekoo = 8'b0010_0010;
	"%": siekoo = 8'b0010_0100;
	"(": siekoo = 8'b0011_1001;
	")": siekoo = 8'b0000_1111;
	"@": siekoo = 8'b0001_0111;
	"*": siekoo = 8'b0100_1001;
	"#": siekoo = 8'b0011_0110;
	"<": siekoo = 8'b0010_0001;
	">": siekoo = 8'b0000_0011;
	//"": siekoo = 8'b0111_1111;
	default: siekoo = 8'b1000_0000;
	endcase
end
endfunction

`endif
