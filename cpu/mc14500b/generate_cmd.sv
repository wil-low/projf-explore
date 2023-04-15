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

function [7:0] instr_label;
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
logic [7:0] labelKB_main_cycle;
logic [7:0] labelKB_T7_eq_1;
logic [7:0] labelBranchTestTMP0eq1;

initial begin
	fd = $fopen("cmd.mem", "wb");
	fdh = $fopen("cmd.mem.svh", "w");

	labelBranchTestTMP0eq1 = 
	//instr(`I_ORC, `INPUT_RR);
	instr(`I_STO, `OUTPUT_1);
	instr(`I_STOC, `OUTPUT_1);
	
	instr_label("CmdBranchTest", "BranchingTest");
	instr(`I_LDC, `INPUT_RR);  // run once when RR == 0 (after reset)
	instr(`I_OEN, `INPUT_RR);
	instr(`I_STO,  `TMP_0);
	instr(`I_STO, `OUTPUT_3);
	instr(`I_STOC, `OUTPUT_3);
	// enable
	instr(`I_ORC, `INPUT_RR);
	instr(`I_IEN, `INPUT_RR);
	instr(`I_OEN, `INPUT_RR);

	instr(`I_LD,  `TMP_0);
	instr(`I_STOC, `TMP_0);

	instr(`I_SKZ, 0);  // skip next if RR == 0
	instr_jmp(labelBranchTestTMP0eq1);
	instr(`I_ORC, `INPUT_RR);
	instr(`I_STO, `OUTPUT_0);
	instr(`I_STOC, `OUTPUT_0);
	instr(`I_NOPF, 0);


	instr_label("CmdFPGA", "FPGA routine");
	instr(`I_ORC, `INPUT_RR);
	instr(`I_IEN, `INPUT_RR);
	instr(`I_LD, `INPUT_1);
	instr(`I_AND, `INPUT_2);
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
	instr(`I_STO, `TMP_0);
	labelFPGA = instr(`I_LDC, `TMP_0);
	instr(`I_STO, `TMP_0);
	//instr(`I_STO, `OUTPUT_0);
	instr(`I_STO, `OUTPUT_1);
	instr(`I_STO, `OUTPUT_2);
	instr(`I_STO, `OUTPUT_3);
	//instr(`I_NOPF, 0);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOP0, f);
	//instr(`I_NOPF, f);
	instr_jmp(labelFPGA);
	instr(`I_NOP0, 0);

//===========================

	labelKB_T7_eq_1 = 
	instr_label("lblT7eq1", "Kill the Bit game: T7 == 1");
	instr(`I_ORC, `INPUT_RR);
	//instr(`I_STO,  `OUTPUT_3); //*

	instr(`I_LD,  `TMP_6); // T7 == 1
	instr(`I_STO, `TMP_7);
	instr(`I_LD,  `TMP_5);
	instr(`I_STO, `TMP_6);
	instr(`I_LD,  `TMP_4);
	instr(`I_STO, `TMP_5);
	instr(`I_LD,  `TMP_3);
	instr(`I_STO, `TMP_4);
	instr(`I_LD,  `TMP_2);
	instr(`I_STO, `TMP_3);
	instr(`I_LD,  `TMP_1);
	instr(`I_STO, `TMP_2);
	instr(`I_ORC, `INPUT_RR);
	instr(`I_STO, `TMP_1); // T7 => T1 (==1)

	instr_label("CmdKillbits", "Kill the Bit game");
	instr(`I_LDC, `INPUT_RR);  // run once when RR == 0 (after reset)
	instr(`I_OEN, `INPUT_RR);
	// initialize bits
	instr(`I_STO, `TMP_1);  // this one is lit
	instr(`I_STOC, `TMP_2);
	instr(`I_STOC, `TMP_3);
	instr(`I_STOC, `TMP_4);
	instr(`I_STOC, `TMP_5);
	instr(`I_STOC, `TMP_6);
	instr(`I_STOC, `TMP_7);

	labelKB_main_cycle = 
	instr(`I_ORC, `INPUT_RR);
	instr(`I_IEN, `INPUT_RR);
	instr(`I_OEN, `INPUT_RR);

	// copy from temp to output
	instr(`I_LD,  `TMP_1);
	instr(`I_STO, `OUTPUT_1);
	instr(`I_LD,  `TMP_2);
	instr(`I_STO, `OUTPUT_2);
	instr(`I_LD,  `TMP_3);
	instr(`I_STO, `OUTPUT_3);
	instr(`I_LD,  `TMP_4);
	instr(`I_STO, `OUTPUT_4);
	instr(`I_LD,  `TMP_5);
	instr(`I_STO, `OUTPUT_5);
	instr(`I_LD,  `TMP_6);
	instr(`I_STO, `OUTPUT_6);
	instr(`I_LD,  `TMP_7);
	instr(`I_STO, `OUTPUT_7);
	// xnor with input
	instr(`I_LD,  `TMP_1);
	instr(`I_XNOR, `INPUT_1);
	instr(`I_STO, `TMP_1);
	instr(`I_LD,  `TMP_2);
	instr(`I_XNOR, `INPUT_2);
	instr(`I_STO, `TMP_2);
	instr(`I_LD,  `TMP_3);
	instr(`I_XNOR, `INPUT_3);
	instr(`I_STO, `TMP_3);
	instr(`I_LD,  `TMP_4);
	instr(`I_XNOR, `INPUT_4);
	instr(`I_STO, `TMP_4);
	instr(`I_LD,  `TMP_5);
	instr(`I_XNOR, `INPUT_5);
	instr(`I_STO, `TMP_5);
	instr(`I_LD,  `TMP_6);
	instr(`I_XNOR, `INPUT_6);
	instr(`I_STO, `TMP_6);
	instr(`I_LD,  `TMP_7);
	instr(`I_XNOR, `INPUT_7);
	instr(`I_STO, `TMP_7);
	
	instr(`I_SKZ, 0);  // skip next if T7 == 0
	instr_jmp(labelKB_T7_eq_1);
	instr(`I_LD,  `TMP_6); // T7 == 0
	instr(`I_STO, `TMP_7);
	instr(`I_LD,  `TMP_5);
	instr(`I_STO, `TMP_6);
	instr(`I_LD,  `TMP_4);
	instr(`I_STO, `TMP_5);
	instr(`I_LD,  `TMP_3);
	instr(`I_STO, `TMP_4);
	instr(`I_LD,  `TMP_2);
	instr(`I_STO, `TMP_3);
	instr(`I_LD,  `TMP_1);
	instr(`I_STO, `TMP_2);
	instr(`I_ORC, `INPUT_RR);
	instr(`I_STOC, `TMP_1); // T7 => T1 (== 0)

	instr(`I_NOPF, 0);


	//instr(`I_ORC, `INPUT_RR);
	//instr(`I_STO, `OUTPUT_2);
	//instr(`I_STOC, `OUTPUT_2);

	instr_label("CmdMaxSize", "Max file size");

	$fclose(fd);
	$fclose(fdh);
end

endmodule
