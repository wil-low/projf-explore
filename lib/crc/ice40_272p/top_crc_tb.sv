`default_nettype none
`timescale 1ns / 1ps

module top_crc_tb();
	parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

	localparam CRC_WIDTH = 32;

	logic clk;
	logic crc_en;
	logic crc_idle;
	logic crc_ready;
	logic [CRC_WIDTH - 1 : 0] crc_output;

	//localparam DATA_LEN = 9 * 8;
	//logic [DATA_LEN - 1 : 0] str = "123456789";
	//// CRC-32/POSIX	32	0x04C11DB7	0x0	false	false	0xFFFFFFFF	0x765E7680
	//crc #(.WIDTH(CRC_WIDTH), .INIT(32'h0), .DATA_LEN(DATA_LEN), .XOR_OUT(32'hFFFFFFFF))
	//	crc_inst (clk, str, crc_en, crc_idle, crc_ready, crc_output);

	localparam DATA_LEN = 43 * 8;
	logic [DATA_LEN - 1 : 0] str = "The quick brown fox jumps over the lazy dog";
	// CRC-32/MPEG-2	32	0x04C11DB7	0xFFFFFFFF	false	false	0x0	0x376E6E7
	crc #(.WIDTH(CRC_WIDTH), .INIT(32'hFFFFFFFF), .DATA_LEN(DATA_LEN), .XOR_OUT(32'hFFFFFFFF))
		crc_inst (clk, str, crc_en, crc_idle, crc_ready, crc_output);

    // generate clock
    always #(CLK_PERIOD / 2) clk <= ~clk;

    initial begin
		$dumpfile("top_crc_tb.vcd");
        $dumpvars(0, top_crc_tb);
		crc_en = 0;
        clk = 1;
		#20 crc_en = 1;

		@(negedge crc_idle) crc_en = 0;

		@(posedge crc_ready) $display("\nResult: %x\n", crc_output);

        #300 $finish;
    end

endmodule
