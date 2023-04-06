`default_nettype none
`timescale 1ns / 1ps

`include "cmd.mem.svh"

module mc14500b_demo
#(
	parameter INIT_F = "",
	parameter START_ADDRESS = 8'b0,
	parameter FLG0_HALT = 1'b0,
	parameter FLGF_LOOP = 1'b0
)
(
	input logic RST,
	input logic CLK,
	input logic [7:1] INPUT,
	output reg [7:0] OUTPUT,
	output reg [7:0] TRACE
);

logic	DATA_IN;
logic	DATA_OUT;
logic	RR;
logic	WRITE;
logic	JMP;
logic	RTN;
logic	FLG0;
logic	FLGF;
logic	[7:0] TMP;

logic [7:0] cmd_rom_addr;
logic [7:0] cmd_rom_data;

logic halted = 1'b0;

rom_async #(
	.WIDTH(8),
	.DEPTH(256),
	.INIT_F(INIT_F)
) cmd_rom (
	.addr(cmd_rom_addr),
	.data(cmd_rom_data)
);

/* verilator lint_off PINCONNECTEMPTY */
mc14500b mc14500b_inst (.RST, .X2(CLK & ~RST & ~halted), .INSTR(cmd_rom_data[7:4]), .DATA_IN, .DATA_OUT, .X1(), .RR, .WRITE, .JMP, .RTN, .FLG0, .FLGF);
/* verilator lint_on PINCONNECTEMPTY */

wire [15:0] inputs;
assign inputs = {TMP, INPUT, RR};

assign DATA_IN = inputs[saved_operand];

logic [3:0] saved_operand;

always @(posedge CLK) begin
	$display("posedge CLK, cmd_rom_data %x, addr %b, saved_operand %h, WRITE %b", cmd_rom_data, cmd_rom_addr, saved_operand, WRITE);
	if (RST) begin
		$display("RESET demo");
		cmd_rom_addr <= START_ADDRESS;
		saved_operand <= cmd_rom_data[3:0];
		TMP <= 0;
		OUTPUT <= 0;
	end
	else if (FLG0_HALT && FLG0) begin
		halted <= 1'b1;
		$display("negedge CLK, HALT");
	end
	else if (FLGF_LOOP && FLGF) begin
		cmd_rom_addr <= START_ADDRESS;
		$display("negedge CLK, LOOP to %x", START_ADDRESS);
	end
	else if (JMP) begin
		cmd_rom_addr <= cmd_rom_data;
		$display("negedge CLK, JMP to %x", cmd_rom_data);
	end
	else begin
		if (WRITE) begin
			$display("posedge CLK, cmd_rom_data %x, addr %b, JMP %b, saved_operand %h, DATA_IN %b, DATA_OUT %h, WRITE %b", cmd_rom_data, cmd_rom_addr, JMP, saved_operand, DATA_IN, DATA_OUT, WRITE);
			if (saved_operand[3])
				TMP[saved_operand[2:0]] <= DATA_OUT;
			else
				OUTPUT[saved_operand[2:0]] <= DATA_OUT;
		end
		$display("INPUT, cmd_rom_data %x, addr %b, JMP %b, saved_operand %h, DATA_IN %b, DATA_OUT %h, WRITE %b", cmd_rom_data, cmd_rom_addr, JMP, saved_operand, DATA_IN, DATA_OUT, WRITE);
		cmd_rom_addr <= cmd_rom_addr + 1;
	end

	saved_operand <= cmd_rom_data[3:0];
	TRACE <= cmd_rom_addr;
end

logic _unused_ok = &{1'b1, RTN, 1'b0};

endmodule
