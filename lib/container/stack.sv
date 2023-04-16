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

	input logic push_en,			  	// push enable (add on top)
	input logic pop_en,			  		// pop enable (remove from top)
	input logic peek_en,			  	// peek enable (return item at index, no change)
	input logic poke_en,			  	// poke enable (replace item at index)

	input logic [WIDTH-1:0] data_in,	// data to push|poke
	input logic [$clog2(DEPTH):0] index,	// element index t (0 is top)

	output logic [WIDTH-1:0] data_out, 	// data returned for pop|peek

	output logic full,					// buffer is full
	output logic empty,					// buffer is empty
	output logic [$clog2(DEPTH):0] depth	// returns how many items are in stack
);

logic [$clog2(DEPTH):0] addr_write;

logic [$clog2(DEPTH):0] addr_write_proxy, addr_read_proxy;
logic we_proxy;

assign we_proxy = (push_en && !full) || (poke_en && index < depth);
assign addr_write_proxy = poke_en ? addr_write - index - 1: addr_write;
assign addr_read_proxy = peek_en ? addr_write - index - 1: addr_write - 1;

assign full = addr_write >= DEPTH;
assign empty = addr_write == 0;
assign depth = addr_write;

bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH))
bram_sdp_inst (
	.clk_write(clk), .clk_read(clk), .we(we_proxy),
	.addr_write(addr_write_proxy), .addr_read(addr_read_proxy),
	.data_in(data_in), .data_out(data_out)
);

always_ff @(posedge clk) begin
	if (!rst_n) begin
		$display("stack rst_n");
		addr_write <= 0;
	end
	else begin
		if (push_en && !full)
			addr_write <= addr_write + 1;
		else if (pop_en && !empty)
			addr_write <= addr_write - 1;
	end
end

endmodule
