`default_nettype none
`timescale 1ns / 1ps

`include "cmd.mem.svh"

module mc14500b_demo
#(
	parameter INIT_F = ""
)
(
	input RST,
	input CLK,
	input [7:1] INPUT,
	output logic [7:0] OUTPUT
);

wire	DATA;
logic	RR;
logic	WRITE;
logic	JMP;
logic	RTN;
logic	FLG0;
logic	FLGF;
logic	[7:0] SCRATCHPAD;

logic [7:0] cmd_rom_addr;
logic [7:0] cmd_rom_data;

rom_async #(
	.WIDTH(8),
	.DEPTH(256),
	.INIT_F(INIT_F)
) cmd_rom (
	.addr(cmd_rom_addr),
	.data(cmd_rom_data)
);

/* verilator lint_off PINCONNECTEMPTY */
mc14500b mc14500b_inst (.RST, .X2(CLK & ~RST), .INSTR(cmd_rom_data[7:4]), .DATA, .X1(), .RR, .WRITE, .JMP, .RTN, .FLG0, .FLGF);
/* verilator lint_on PINCONNECTEMPTY */

wire [15:0] inputs;
assign inputs = {SCRATCHPAD, INPUT, RR};

assign DATA = WRITE ? 1'bz : inputs[cmd_rom_data[3:0]];

logic [3:0] saved_operand;

always @(posedge CLK) begin
	$display("posedge CLK, cmd_rom_data %x, addr %b, saved_operand %h, WRITE %b", cmd_rom_data, cmd_rom_addr, saved_operand, WRITE);
	if (RST) begin
		SCRATCHPAD <= 0;
		OUTPUT <= 0;
	end
	else if (WRITE) begin
		$display("posedge CLK, cmd_rom_data %x, addr %b, JMP %b, saved_operand %h, DATA %h, WRITE %b", cmd_rom_data, cmd_rom_addr, JMP, saved_operand, DATA, WRITE);
		if (saved_operand[3])
			SCRATCHPAD[saved_operand[2:0]] <= DATA;
		else
			OUTPUT[saved_operand[2:0]] <= DATA;
	end
end

always @(negedge CLK) begin
	if (RST) begin
		cmd_rom_addr <= 0;
		saved_operand <= cmd_rom_data[3:0];
	end
	else begin
		if (!JMP) begin
			cmd_rom_addr <= cmd_rom_addr + 1;
		end
		else
			cmd_rom_addr <= cmd_rom_data;
		saved_operand <= cmd_rom_data[3:0];
	end
end

logic _unused_ok = &{1'b1, RTN, FLG0, FLGF, 1'b0};

endmodule
