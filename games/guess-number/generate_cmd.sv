`default_nettype none
`timescale 1ns / 1ps

module generate_cmd();

integer fd;

`include "cmd_flags.svh"

function label;
begin
	//label = cmd_offset;
end
endfunction

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
		$fwrite(fd, "%x ", data[i]);
	end
	$fwrite(fd, "\n");
end
endtask

task instr_state;
	input [7:0] state;
begin
	$fwrite(fd, "00 00 00 00 ");
	$fwrite(fd, "%x\n", state);
end
endtask

initial begin
	//cmd_offset = 0;
	fd = $fopen("cmd.mem", "wb");
	instr(`SEND_2ND_NIBBLE, 1000 * 1000, 8'h00);  // reset expander and turn backlight off
	instr(`WITH_PULSE, 4500, 8'h30);  // we start in 8bit mode, try to set 4 bit mode
	instr(`WITH_PULSE, 4500, 8'h30);  // second try
	instr(`WITH_PULSE, 150, 8'h30);  // third go!
	instr(`WITH_PULSE, 150, 8'h20);  // finally, set to 4-bit interface
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 10, 8'h28);  // set # lines, font size, etc.
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 10, 8'h0c);   // turn the display on with no cursor or blinking default
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 2000, 8'h01);   // clear it off
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 2000, 8'h06);   // set the entry mode
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE, 2000, 8'h02);   // return home
	instr(`SEND_2ND_NIBBLE | `BACKLIGHT, 10, 8'h00);   // backlight
	instr_data(`BACKLIGHT, 10, "Guess a number");
	instr(`WITH_PULSE | `SEND_2ND_NIBBLE | `BACKLIGHT, 10, 8'h80 + 8'h40);   // setCursor
	instr_data(`BACKLIGHT, 10, {"from 0 to 256  ", 8'b01111110});
	instr_state(8'h00);  // go to state IDLE
	$fclose(fd);
end

endmodule
