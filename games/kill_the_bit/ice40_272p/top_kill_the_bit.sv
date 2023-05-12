`default_nettype none
`timescale 1ns / 1ps

module top_kill_the_bit
(
	input wire CLK,
	
	output logic LK_CLK,
	inout  wire  LK_DIO,
	output logic LK_STB,
	
	output logic [7:0] LED,
	output logic CLK_COPY,
	output logic STB_COPY,
	output logic DIO_COPY
);

assign CLK_COPY = LK_CLK;
assign STB_COPY = LK_STB;
assign DIO_COPY = LK_DIO;

//// Reset emulation for ice40
logic [7:0] reset_counter = 0;
logic rst_n = &reset_counter;

always @(posedge CLK) begin
	if (!rst_n)
		reset_counter <= reset_counter + 1;
end

kill_the_bit
#(
	.CLOCK_FREQ_MHz(12)
)
kill_the_bit_inst
(
	.i_clk(CLK),
	.rst_n(rst_n),
	.o_ledkey_clk(LK_CLK),
	.o_ledkey_stb(LK_STB),
	.io_ledkey_dio(LK_DIO),
	.o_LED(LED)
);

wire _unused_ok = &{1'b1, 1'b0};

endmodule
