`default_nettype none
`timescale 1ns / 1ps

module intel_hex_tb();

parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
localparam INIT_F = "collatz.hex";

logic clk;
logic i_en = 0;		  		// data arrived
logic [7:0] i_data;			// byte from stream
logic [15:0] o_addr;		// target address
logic [7:0] o_data;			// output byte
logic o_idle;				// idle, waiting for data
logic o_data_valid;			// output data ready
logic [2:0] o_error_code;	// error code

// generate clock
always #(CLK_PERIOD / 2) clk <= ~clk;

intel_hex
intel_hex_inst (
	.i_clk(clk),
	.i_en,
	.i_data,
	.o_addr,
	.o_data,
	.o_idle,
	.o_data_valid,
	.o_error_code
);

initial begin
	$dumpfile("top_stack_tb.vcd");
	$dumpvars(0, top_stack_tb);
	clk = 1;

	integer fd;
	fd = $fopen(INIT_F, "r");
	if (fd)
		$display("File %s opened", INIT_F);
	else
		$display("Cannot open file %s", INIT_F);
	
	integer ch;
	while ((ch = $fgetc(fd)) != -1) begin
		#20;
		i_data = ch;
		i_en <= 1;

		#10;
		i_en <= 0;
		if (o_error_code) begin
			$display("error_code %d", o_error_code);
			break;
		end
	end

	$fclose(fd);

	#10 $finish;
end

endmodule
