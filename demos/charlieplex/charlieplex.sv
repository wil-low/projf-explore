`default_nettype none
`timescale 1ns / 1ps

module charlieplex
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
	inout wire [2:0] io_pin
);

logic [20:0] counter = ~0;

logic [3 * 2 - 1:0] signal;  // {en2, en1, en0, out2, out1, out0}
logic [2:0] active_pin = 0;

/* verilator lint_off PINCONNECTEMPTY */
genvar i;
generate
for (i = 0; i < 3; i = i + 1) begin : gen_inout
	sb_inout sb_inout_inst (.pin(io_pin[i]), .out_enable(signal[i + 3]), .out_value(signal[i]), .in_value());
end
endgenerate
/* verilator lint_on PINCONNECTEMPTY */

always @(posedge i_clk) begin
	counter <= counter + 1;
	if (counter == 0) begin
		case (active_pin)
		0: signal <= 6'b011?01;
		1: signal <= 6'b011?10;
		2: signal <= 6'b1010?1;
		3: signal <= 6'b1011?0;
		4: signal <= 6'b11001?;
		5: signal <= 6'b11010?;
		default: begin
		end
		endcase
		active_pin <= (active_pin == 5) ? 0 : active_pin + 1;
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
