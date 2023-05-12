`default_nettype none
`timescale 1ns / 1ps

module kill_the_bit
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
	input wire rst_n,
	
	output logic o_ledkey_clk,
	output logic o_ledkey_stb,
	inout  wire  io_ledkey_dio,
	
	output logic [7:0] o_LED
);

logic cmd_en = 0;
logic seg7_en = 0;
logic led_en = 0;
logic all_led_en = 0;
logic btn_en = 0;
logic batch_en = 0;
logic [2:0] idx = 0;
logic [7:0] data = 0;
logic [7:0] btn_state;
logic [4:0] batch_data_size;
logic [8 * 17 - 1 : 0] batch_data;

logic ledkey_idle;

assign o_LED = ledkey_idle ? ~btn_state : ~0;

tm1638_led_key
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
)
tm1638_led_key_inst
(
	.i_clk(i_clk),
	.i_cmd_en(cmd_en),					// enable sending raw data
	.i_seg7_en(seg7_en),				// enable setting one seg7's state
	.i_led_en(led_en),					// enable setting one LED state
	.i_all_led_en(all_led_en),			// enable setting all LED states at once
	.i_batch_en(batch_en),				// enable sending up to 17 bytes of batch_data
	.i_btn_en(btn_en),					// enable reading buttons' state

	.i_idx(idx),						// seg7/led index (0-7)

	.i_data(data),					// byte to send
	.o_btn_state(btn_state),			// button0-7 state (1 = pressed) 

	.i_batch_data_size(batch_data_size),
	.i_batch_data(batch_data),
	.i_wait_counter(wait_counter),

	// shield pins
	.o_tm1638_clk(o_ledkey_clk),
	.o_tm1638_stb(o_ledkey_stb),
	.io_tm1638_data(io_ledkey_dio),

	.o_idle(ledkey_idle)
);

enum {
	s_INIT, s_IDLE
} state;

logic [5:0] state_counter;

localparam ONE_USEC = CLOCK_FREQ_MHz;
localparam ONE_SEC = 10;//ONE_USEC * 1000000;

logic [27:0] wait_counter = 0;

logic [7:0] led_counter;

task send_cmd;
	input [7:0] cmd2send;
	input [27:0] wait_cycles;
begin
	data <= cmd2send;
	wait_counter <= wait_cycles;
	cmd_en <= 1;
end
endtask

task send_batch;
	input [4:0] size;
	input [8 * 17 - 1 : 0] data2send;
	input [27:0] wait_cycles;
begin
	batch_data_size <= size;
	batch_data <= data2send;
	wait_counter <= wait_cycles;
	batch_en <= 1;
end
endtask

task set_seg7;
	input [3:0] index;
	input [7:0] data2send;
	input [27:0] wait_cycles;
begin
	idx <= index;
	data <= data2send;
	wait_counter <= wait_cycles;
	seg7_en <= 1;
end
endtask

task set_led;
	input [3:0] index;
	input data2send;
	input [27:0] wait_cycles;
begin
	idx <= index;
	data[0] <= data2send;
	wait_counter <= wait_cycles;
	led_en <= 1;
end
endtask

task set_all_led;
	input [7:0] data2send;
	input [27:0] wait_cycles;
begin
	data <= data2send;
	wait_counter <= wait_cycles;
	all_led_en <= 1;
end
endtask

function [7:0] siekoo;
	input [7:0] c;
begin
	// https://fakoo.de/en/siekoo.html
	case (c)
	"0": siekoo = 8'b0011_1111;
	"1": siekoo = 8'b0000_0110;
	"2": siekoo = 8'b0101_1011;
	"3": siekoo = 8'b0100_1111;
	"4": siekoo = 8'b0110_0110;
	"5": siekoo = 8'b0110_1101;
	"6": siekoo = 8'b0111_1101;
	"7": siekoo = 8'b0000_0111;
	"8": siekoo = 8'b0111_1111;
	"9": siekoo = 8'b0110_1111;
	"a": siekoo = 8'b0101_1111;
	"b": siekoo = 8'b0111_1100;
	"c": siekoo = 8'b0101_1000;
	"d": siekoo = 8'b0101_1110;
	"e": siekoo = 8'b0111_1001;
	"f": siekoo = 8'b0111_0001;
	"g": siekoo = 8'b0011_1101;
	"h": siekoo = 8'b0111_0100;
	"i": siekoo = 8'b0001_0001;
	"j": siekoo = 8'b0000_1101;
	"k": siekoo = 8'b0111_0101;
	"l": siekoo = 8'b0011_1000;
	"m": siekoo = 8'b0101_0101;
	"n": siekoo = 8'b0101_0100;
	"o": siekoo = 8'b0101_1100;
	"p": siekoo = 8'b0111_0011;
	"q": siekoo = 8'b0110_0111;
	"r": siekoo = 8'b0101_0000;
	"s": siekoo = 8'b0010_1101;
	"t": siekoo = 8'b0111_1000;
	"u": siekoo = 8'b0001_1100;
	"v": siekoo = 8'b0010_1010;
	"w": siekoo = 8'b0110_1010;
	"x": siekoo = 8'b0001_0100;
	"y": siekoo = 8'b0110_1110;
	"z": siekoo = 8'b0001_1011;
	" ": siekoo = 8'b0000_0000;
	".": siekoo = 8'b0001_0000;
	",": siekoo = 8'b0000_1100;
	";": siekoo = 8'b0000_1010;
	":": siekoo = 8'b0000_1001;
	"=": siekoo = 8'b0100_1000;
	"+": siekoo = 8'b0100_0110;
	"/": siekoo = 8'b0101_0010;
	8'h5c:siekoo = 8'b0110_0100; // backslash
	"!": siekoo = 8'b0110_1011;
	"?": siekoo = 8'b0100_1011;
	"_": siekoo = 8'b0000_1000;
	"-": siekoo = 8'b0100_0000;
	"^": siekoo = 8'b0000_0001;
	"'": siekoo = 8'b0010_0000;
	"\"":siekoo = 8'b0010_0010;
	"%": siekoo = 8'b0010_0100;
	"(": siekoo = 8'b0011_1001;
	")": siekoo = 8'b0000_1111;
	"@": siekoo = 8'b0001_0111;
	"*": siekoo = 8'b0100_1001;
	"#": siekoo = 8'b0011_0110;
	"<": siekoo = 8'b0010_0001;
	">": siekoo = 8'b0000_0011;
	//"": siekoo = 8'b0111_1111;
	default: siekoo = 8'b1000_0000;
	endcase
end
endfunction

always @(posedge i_clk) begin
	{cmd_en, seg7_en, led_en, batch_en, btn_en, all_led_en} <= 0;

	if (!rst_n) begin
		state <= s_INIT;
		state_counter <= 0;
		led_counter <= 0;
		$display($time, "RESET");
	end
	else begin
		case (state)

		s_INIT: begin
			if (ledkey_idle) begin
				case (state_counter)
				0: begin
					send_cmd(8'h40, 0);  // set auto increment mode
				end
				1: begin
					send_batch(17, {8'hc0, 128'h0}, 0);  // set starting address to 0, then send 16 zero bytes
				end
				2: begin
					send_cmd(8'h88, ONE_SEC);  // activate
				end
				3: begin
					send_batch(17, {
							8'hc0,
							siekoo("k"), 8'h00,
							siekoo("i"), 8'h00,
							siekoo("l"), 8'h00,
							siekoo("l"), 8'h00,
							siekoo(" "), 8'h00,
							siekoo("b"), 8'h00,
							siekoo("i"), 8'h00,
							siekoo("t"), 8'h00
						},
						ONE_SEC * 16);
				end
				4: begin
					//set_seg7(4, 8'h40, ONE_SEC);
				end
				5: begin
					set_led(7, 1, ONE_SEC);
				end
				6: begin
					set_all_led(8'b11001111, ONE_SEC);
				end
				7: begin
					send_cmd(8'h80, ONE_SEC);  // deactivate
				end
				8: begin
					send_cmd(8'h8d, ONE_SEC);  // activate
				end
				9: begin
					send_cmd(8'h88, ONE_SEC);  // activate
				end
				default:
					state <= s_IDLE;
				endcase

				if (state_counter == 20)
					state <= s_IDLE;
				else
					state_counter <= state_counter + 1;
			end
		end

		s_IDLE: begin
			if (ledkey_idle) begin
				btn_en <= 1;

				/*set_all_led(1 << led_counter, ONE_USEC * 60000);
				if (led_counter == 8)
					led_counter <= 0;
				else
					led_counter <= led_counter + 1;*/
			end
		end

		default:
			state <= s_INIT;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
