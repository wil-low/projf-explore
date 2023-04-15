// UART TX

`default_nettype none
`timescale 1ns / 1ps

module uart_tx
#(
	parameter CLOCK_FREQ_Mhz = 12,
	parameter BAUD_RATE = 9600,
	parameter PARITY_MODE = 2'b00  // 00 - none, 01 - odd, 10 - even
)
(
	input logic i_Clock,
	input logic [7:0] i_Data,
	input logic i_Start,
	//
	output logic o_Data,
	output logic o_Idle,

	output logic [2:0] sm_state,
	output logic [2:0] bit_counter
);
/* verilator lint_off WIDTH */
localparam COUNTER_LIMIT = CLOCK_FREQ_Mhz * 1_000_000 / BAUD_RATE;

logic [7:0] tx_buffer;
logic [$clog2(COUNTER_LIMIT) - 1:0] counter;
//logic [2:0] bit_counter;

localparam s_IDLE = 3'b000;
localparam s_WORKING = 3'b001;
localparam s_PARITY = 3'b010;
localparam s_STOP = 3'b011;
localparam s_DONE = 3'b100;

always @(posedge i_Clock) begin

	case (sm_state)

	s_IDLE: begin
		if (i_Start) begin
			tx_buffer <= i_Data;  // save input into buffer
			o_Data <= 0; // send start bit
			counter <= 0;
			bit_counter <= 0;
			o_Idle <= 0; // busy
			sm_state <= s_WORKING;
		end
		else begin
			o_Idle <= 1;
			o_Data <= 1;
		end
	end

	s_WORKING: begin
		if (counter == COUNTER_LIMIT) begin
			// send next bit
			o_Data <= tx_buffer[bit_counter];
			counter <= 0;
			if (bit_counter == 7) begin
				sm_state <= (PARITY_MODE != 0) ? s_PARITY : s_STOP;
			end
			else
				bit_counter <= bit_counter + 1;
		end
		else
			counter <= counter + 1;
	end
	
	s_PARITY: begin
		bit_counter <= 0; // delete
		if (counter == COUNTER_LIMIT) begin
			// send parity bit
			counter <= 0;
			o_Data <= (^tx_buffer ^ PARITY_MODE[0]);
			sm_state <= s_STOP;
		end
		else
			counter <= counter + 1;
	end
	
	s_STOP: begin
		bit_counter <= 0; // delete
		if (counter == COUNTER_LIMIT) begin
			// send stop bit
			counter <= 0;
			o_Data <= 1;
			sm_state <= s_DONE;
		end
		else
			counter <= counter + 1;
	end
	
	s_DONE: begin
		if (counter == COUNTER_LIMIT) begin
			o_Idle <= 1;
			sm_state <= s_IDLE;
		end
		else
			counter <= counter + 1;
	end
	
	default: begin
		sm_state <= s_IDLE;
	end
	
	endcase
end
/* verilator lint_on WIDTH */
endmodule
