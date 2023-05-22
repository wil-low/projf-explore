`default_nettype none
`timescale 1ns / 1ps

module top_intel_hex_tb();

parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
localparam INIT_F = "../test.hex";

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

integer fd, ch;

initial begin
	$dumpfile("top_intel_hex_tb.vcd");
	$dumpvars(0, top_intel_hex_tb);
	clk = 1;

	fd = $fopen(INIT_F, "r");
	if (fd)
		$display("File %s opened", INIT_F);
	else
		$display("Cannot open file %s", INIT_F);
	
	ch = $fgetc(fd);
	while (ch != -1) begin
		#10;
		i_data = ch;
		i_en <= 1;

		#10;
		i_en <= 0;
		if (o_error_code) begin
			$display("error_code %d", o_error_code);
			$fclose(fd);
			$finish;
		end
		ch = $fgetc(fd);
	end

	$fclose(fd);

	$display("File '%s' processed without errors", INIT_F);

	#10 $finish;
end

endmodule
