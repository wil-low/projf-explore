`default_nettype none
`timescale 1ns / 1ps

module stack
#(
	parameter WIDTH = 8, 
	parameter DEPTH = 256
)
(
	input wire logic clk,
	input wire logic rst_n,					// reset
	input wire logic push_en,			  	// push enable (add on top)
	input wire logic pop_en,			  	// pop enable (remove from top)
	input wire logic peek_en,			  	// peek enable (return item at index, no change)
	input wire logic poke_en,			  	// poke enable (replace item at index)
	input wire logic [WIDTH - 1:0] data_in,	// data to push|poke
	input wire logic [$clog2(DEPTH) - 1:0] index,	// element index t (0 is top)

	output logic [WIDTH-1:0] data_out, 	// data returned for pop|peek

	output logic full,					// buffer is full
	output logic empty,					// buffer is empty
	output logic [$clog2(DEPTH):0] depth	// returns how many items are in stack
);

logic [$clog2(DEPTH) - 1:0] addr_write;

logic [$clog2(DEPTH) - 1:0] addr_write_proxy, addr_read_proxy;
logic we_proxy;

assign we_proxy = (push_en && !full) || (poke_en && index < depth);
assign addr_write_proxy = poke_en ? addr_write - index - 1: addr_write;
assign addr_read_proxy = peek_en ? addr_write - index - 1: addr_write - 1;

assign full = addr_write >= DEPTH;
assign empty = addr_write == 0;
assign depth = addr_write;

bram_read_async #(.WIDTH(WIDTH), .DEPTH(DEPTH))
bram_read_async_inst (
	.clk, .we(we_proxy),
	.addr_write(addr_write_proxy), .addr_read(addr_read_proxy),
	.data_in(data_in), .data_out(data_out)
);

always @(posedge clk) begin
	if (!rst_n) begin
		//$display("stack rst_n");
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
