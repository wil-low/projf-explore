`default_nettype none
`timescale 1ns / 1ps

module generate_cmd();

integer fd, fdh;

`include "instructions.svh"

function [7:0] instr;
	input [3:0] cmd;
	input [3:0] data;
begin
	instr = $ftell(fd) / 3;
	$fwrite(fd, "%x\n", {cmd, data});
end
endfunction

function [7:0] instr_jmp;
	input [7:0] address;
begin
	instr_jmp = $ftell(fd) / 3;
	$fwrite(fd, "%x %x\n", {`I_JMP, 4'b0}, address);
end
endfunction

function instr_label;
	input string name;
	input string comment;
begin
	instr_label = $ftell(fd) / 3;
	$fwrite(fdh, "`define ");
	$fwrite(fdh, name);
	$fwrite(fdh, $ftell(fd) / 3);
	$fwrite(fdh, "  // ");
	$fwrite(fdh, comment);
	$fwrite(fdh, "\n");
end
endfunction

logic [7:0] labelBegin;
logic [7:0] labelFPGA;

initial begin
	fd = $fopen("cmd.mem", "wb");
	fdh = $fopen("cmd.mem.svh", "w");

	//instr_label("CmdStart", "Very beginning");
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_IEN, `INPUT_RR);
	//instr(`I_OEN, `INPUT_RR);
	//instr(`I_LDC, `INPUT_RR);
	//instr(`I_LD, `INPUT_1);
	//instr(`I_OR, `INPUT_2);
	//instr(`I_OR, `INPUT_3);
	//instr(`I_STO, `SCRATCHPAD_0);
	//instr(`I_ANDC, `INPUT_RR);
	//instr(`I_LD, `SCRATCHPAD_0);
	//instr(`I_NOP0, 0);

	instr_label("CmdFPGA", "FPGA routine");
	instr(`I_ORC, `INPUT_RR);
	instr(`I_IEN, `INPUT_RR);
	instr(`I_OEN, `INPUT_RR);
	//instr(`I_LDC, `INPUT_RR);
	//instr(`I_STO, `OUTPUT_0);
	instr(`I_STO, `OUTPUT_1);
	instr(`I_STO, `OUTPUT_2);
	instr(`I_STO, `OUTPUT_3);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	instr(`I_LDC, `INPUT_RR);
	//instr(`I_STO, `OUTPUT_0);
	instr(`I_STO, `OUTPUT_1);
	instr(`I_STO, `OUTPUT_2);
	instr(`I_STO, `OUTPUT_3);
	instr(`I_NOPF, 0);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOPF, f);
	//instr_jmp(labelFPGA);

	//instr(`I_LDC, `INPUT_RR);
	//instr(`I_STO, `OUTPUT_0);
	//instr(`I_STO, `OUTPUT_1);
	//instr(`I_STO, `OUTPUT_2);
	//instr(`I_STO, `OUTPUT_3);

	//instr(`I_STO, `OUTPUT_0);
	//instr(`I_STOC, `OUTPUT_0);
	//instr(`I_STO, `OUTPUT_0);
	//instr(`I_STOC, `OUTPUT_0);
	//instr(`I_STO, `OUTPUT_0);
	//instr(`I_STOC, `OUTPUT_0);
	//instr(`I_STO, `OUTPUT_1);
	//instr(`I_STOC, `OUTPUT_1);
	//instr(`I_STO, `OUTPUT_2);
	instr(`I_NOP0, 0);
	instr(`I_NOPF, 0);
	//instr_jmp(labelFPGA);

	//instr_label("CmdORC_RR", "ORC RR");
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_STO, `OUTPUT_3);
	//instr(`I_STOC, `OUTPUT_3);
	//instr(`I_NOP0, 0);
	//
	//instr(`I_NOPF, 0);

	//labelLD1 = instr(`I_LD, `INPUT_1);
	//instr(`I_OR, `INPUT_2);
	//instr(`I_STOC, `OUTPUT_0);
	//instr(`I_STOC, `OUTPUT_1);
	//instr(`I_STOC, `OUTPUT_2);
	//instr(`I_STOC, `OUTPUT_3);
	//instr_jmp(labelLD1);
	//instr(`I_NOP0, 0);

	instr_label("CmdMaxSize", "Max file size");

	$fclose(fd);
	$fclose(fdh);
end

endmodule
