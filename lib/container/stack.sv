`default_nettype none
`timescale 1ns / 1ps

module stack
#(
	parameter WIDTH = 8, 
	parameter DEPTH = 256
)
(
	input logic clk,

	input logic rst_n,					// reset

	input logic push_en,			  	// push enable (port a)
	input logic [WIDTH-1:0] push_data,	// data to push (port a)

	input logic pop_en,			  	// pop enable (port a)
	output logic [WIDTH-1:0] pop_data, 		// data to pop (port b)

	output logic full,					// buffer is full
	output logic empty,					// buffer is empty
	output logic [$clog2(DEPTH):0] item_count	// buffer is empty
);

logic [$clog2(DEPTH) - 1:0] addr_write, addr_read;
logic do_push;

assign full = addr_write == DEPTH;
assign empty = addr_write == 0;

assign item_count = addr_write;

bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH))
bram_sdp_inst (
	.clk_write(clk), .clk_read(clk), .we(do_push),
	.addr_write(addr_write), .addr_read(addr_read),
	.data_in(push_data), .data_out(pop_data)
);

always_ff @(posedge clk) begin
	if (!rst_n) begin
		addr_write <= 0;
	end
	else begin
		if (push_en && !full) begin
			addr_write <= addr_write + 1;
			addr_read <= addr_write;
			do_push <= 1;
		end
		else begin
			do_push <= 0;
		end
		if (pop_en && !empty) begin
			addr_write <= addr_write - 1;
			addr_read <= addr_read - 1;
		end
	end
end

endmodule
