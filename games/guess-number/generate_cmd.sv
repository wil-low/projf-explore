`default_nettype none
`timescale 1ns / 1ps

module generate_cmd();

integer fd, fdh;

`include "cmd_flags.svh"
`include "custom_chars.svh"

`define RIGHT_ARROW 8'b01111110

task instr;
	input [3:0] flags;
	input [27:0] delay_usec;
	input [7:0] data;
begin
	$fwrite(fd, "%x %x %x %x ", {flags, delay_usec[27 -: 4]}, delay_usec[23 -: 8], delay_usec[15 -: 8], delay_usec[7 -: 8]);
	$fwrite(fd, "%x\n", data);
end
endtask

task instr_data;
	input [3:0] flags;
	input [27:0] delay_usec;
	input string data;
begin
	$fwrite(fd, "%x %x %x %x ",
		{flags | `DATAMODE | `WITH_PULSE | `SEND_2ND_NIBBLE,
		delay_usec[27 -: 4]},
		delay_usec[23 -: 8],
		delay_usec[15 -: 8],
		delay_usec[7 -: 8]);
	$fwrite(fd, "%x ", 8'(data.len()));
	for (integer i = 0; i < data.len(); i = i + 1) begin
		if (data[i] == `CCHAR0 || data[i] == `CCHAR1 || data[i] == `CCHAR2 || data[i] == `CCHAR3 ||
			data[i] == `CCHAR4 || data[i] == `CCHAR5 || data[i] == `CCHAR6 || data[i] == `CCHAR7 )
				$fwrite(fd, "%x", data[i] & 8'h7f);
			else
				$fwrite(fd, "%x", data[i]);
		if (i < data.len() - 1)
			$fwrite(fd, " ");
	end
	$fwrite(fd, "\n");
end
endtask

task instr_return;
begin
	$fwrite(fd, "00 00 00 00 00\n");
end
endtask

task instr_label;
	input string name;
	input string comment;
begin
	$fwrite(fdh, "`define ");
	$fwrite(fdh, name);
	$fwrite(fdh, $ftell(fd) / 3);
	$fwrite(fdh, "  // ");
	$fwrite(fdh, comment);
	$fwrite(fdh, "\n");
end
endtask

task instr_cursor;
	input [6:0] x;
	input [3:0] y;
begin
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE | `BACKLIGHT, 10, 8'h80 + 8'h40 * y + x);
end
endtask

task instr_print;
	input string s;
begin
	instr_data(`BACKLIGHT, 1, s);
end
endtask

task instr_create_char;
	input [7:0] char_index;
	input [0 : 8 * 8 - 1] char_data;
begin
	localparam [27:0] delay_usec = 1;
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE | `BACKLIGHT, 10, 8'h40 | ((char_index & 8'h7f) << 3));
	$fwrite(fd, "%x %x %x %x ",
		{`BACKLIGHT | `DATAMODE | `WITH_PULSE | `SEND_2ND_NIBBLE,
		delay_usec[27 -: 4]},
		delay_usec[23 -: 8],
		delay_usec[15 -: 8],
		delay_usec[7 -: 8]);
	$fwrite(fd, "%x ", 8'd8);
	for (integer i = 0; i < 8; i = i + 1) begin
		$fwrite(fd, "%x", char_data[i * 8 +: 8]);
		if (i < 8 - 1)
			$fwrite(fd, " ");
	end
	$fwrite(fd, "\n");
end
endtask

initial begin
	fd = $fopen("cmd.mem", "wb");
	fdh = $fopen("cmd.mem.svh", "w");

	instr_label("CmdInitAndWelcome", "Init LC");
	instr(`SEND_2ND_NIBBLE, 1000 * 1000, 8'h00);  // reset expander and turn backlight off
	instr(`WITH_PULSE, 4500, 8'h30);  // we start in 8bit mode, try to set 4 bit mode
	instr(`WITH_PULSE, 4500, 8'h30);  // second try
	instr(`WITH_PULSE, 150, 8'h30);  // third go!
	instr(`WITH_PULSE, 150, 8'h20);  // finally, set to 4-bit interface
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 10, 8'h28);  // set # lines, font size, etc.
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 10, 8'h0c);   // turn the display on with no cursor or blinking default
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 2000, 8'h01);   // clear it off
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 2000, 8'h06);   // set the entry mode

	//instr_create_char(`CCHAR0, 64'h04_0e_0e_0e_1f_00_04_00);  // bell
	//instr_create_char(`CCHAR1, 64'h02_03_02_0e_1e_0c_00_00);  // note
	//instr_create_char(`CCHAR2, 64'h00_0e_15_17_11_0e_00_00);  // clock
	//instr_create_char(`CCHAR3, 64'h00_0a_1f_1f_0e_04_00_00);  // heart
	//instr_create_char(`CCHAR4, 64'h00_0c_1d_0f_0f_06_00_00);  // duck
	//instr_create_char(`CCHAR5, 64'h00_01_03_16_1c_08_00_00);  // check
	//instr_create_char(`CCHAR6, 64'h00_1b_0e_04_0e_1b_00_00);  // cross
	//instr_create_char(`CCHAR7, 64'h01_01_05_09_1f_08_04_00);  // retarrow

	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 2000, 8'h02);   // return home
	instr(`SEND_2ND_NIBBLE | `BACKLIGHT, 10, 8'h00);   // backlight
	
	//instr_print({`CCHAR0, `CCHAR1, `CCHAR2, `CCHAR3, `CCHAR4, `CCHAR5, `CCHAR6, `CCHAR7});
	instr_print({"   NumberGame   "});
	
	instr_cursor(0, 1);
	instr_print({"  by wil_low   ", `RIGHT_ARROW});
	instr_return();  // return from cmd sequence

	instr_label("CmdShowRules", "Show game rules");
	instr_cursor(0, 0);
	instr_print("Guess a number  ");
	instr_cursor(0, 1);
	instr_print({"from 0 to 1023 ", `RIGHT_ARROW});
	instr_return();  // return from cmd sequence

	instr_label("CmdShowAttemptPrompt", "Attempt prompt");
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE | `BACKLIGHT, 2000, 8'h02);   // return home
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE | `BACKLIGHT, 2000, 8'h01);   // clear it off
	instr_cursor(0, 0);
	instr_print("Attempt 01: 0000");
	instr_cursor(8, 0);
	instr_return();  // return from cmd sequence

	instr_label("CmdSayLesser", "Say the goal number is lesser");
	instr_cursor(0, 1);
	instr_print("Mine is lesser  ");
	instr_return();  // return from cmd sequence

	instr_label("CmdSayGreater", "Say the goal number is greater");
	instr_cursor(0, 1);
	instr_print("Mine is greater ");
	instr_return();  // return from cmd sequence

	instr_label("CmdSayVictory", "Say You win");
	instr_cursor(0, 1);
	instr_print("You win!!!      ");
	instr_return();  // return from cmd sequence

	instr_label("CmdSayLost", "Say You lost");
	instr_cursor(0, 1);
	instr_print("You lost :(     ");
	instr_return();  // return from cmd sequence

	instr_label("CmdMaxSize", "Max file size");

	$fclose(fd);
	$fclose(fdh);
end

endmodule
