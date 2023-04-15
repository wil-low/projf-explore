`default_nettype none
`timescale 1ns / 1ps

module fifo
#(
	parameter WIDTH = 8, 
	parameter DEPTH = 256
)
(
	input logic clk,
	input logic rst_n,					// reset

	input logic push_en,			  	// push enable (port a)
	input logic [WIDTH-1:0] push_data,	// data to push (port a)

	input logic pop_en,			  		// pop enable (port a)
	output logic [WIDTH-1:0] pop_data, 	// data to pop (port b)

	output logic full,					// buffer is full
	output logic empty					// buffer is empty
);

localparam ADDRW = $clog2(DEPTH);

logic [ADDRW - 1:0] addr_write = 0, addr_read = 0;
logic signed [ADDRW + 1:0] fifo_count = 0;

assign full = fifo_count >= DEPTH;
assign empty = fifo_count <= 0;

bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH))
bram_sdp_inst (
	.clk_write(clk), .clk_read(clk), .we(push_en && !full),
	.addr_write, .addr_read,
	.data_in(push_data), .data_out(pop_data)
);

always_ff @(posedge clk) begin
	if (!rst_n) begin
		fifo_count <= 0;
		addr_write <= 0;
		addr_read <= 0;
	end
	else begin
		if (!(push_en && full) && !(pop_en && empty)) begin
			if (push_en && !pop_en)
				fifo_count <= fifo_count + 1;
			else if (!push_en && pop_en)
				fifo_count <= fifo_count - 1;

			if (push_en) begin
				addr_write <= (addr_write == DEPTH - 1) ? 0 : addr_write + 1;
			end

			if (pop_en) begin
				addr_read <= (addr_read == DEPTH - 1) ? 0 : addr_read + 1;
			end
		end
	end
end

endmodule
