`default_nettype none
`timescale 1ns / 1ps

module fifo
#(
	parameter WIDTH = 8, 
	parameter DEPTH = 256, 
	localparam ADDRW = $clog2(DEPTH)
)
(
	input wire logic clk_write,			   	// write clock (port a)
	input wire logic clk_read,				// read clock (port b)

	input wire logic rst_n,					// reset

	input wire logic push_en,			  	// push enable (port a)
	input wire logic [WIDTH-1:0] push_data,	// data to push (port a)

	input wire logic pop_en,			  	// pop enable (port a)
	output logic [WIDTH-1:0] pop_data, 		// data to pop (port b)

	output wire logic full,					// buffer is full
	output wire logic empty					// buffer is empty
);

logic [ADDRW:0] addr_write, addr_read;
logic do_push;

assign full = addr_write == DEPTH;
assign empty = addr_write == 0;

bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH))
bram_sdp_inst (
	.clk_write, .clk_read, .we(do_push),
	.addr_write, .addr_read,
	.data_in(push_data), .data_out(pop_data)
);

always_ff @(negedge rst_n) begin
	if (!rst_n) begin
		addr_write <= 0;
	end
end

always_ff @(posedge clk_write) begin
	if (push_en && !full) begin
		addr_write <= addr_write + 1;
		addr_read <= addr_write;
		do_push <= 1;
	end
	else begin
		do_push <= 0;
	end
end

always_ff @(posedge clk_read) begin
	if (pop_en && !empty) begin
		addr_write <= addr_write - 1;
		addr_read <= addr_read - 1;
	end
end

endmodule
