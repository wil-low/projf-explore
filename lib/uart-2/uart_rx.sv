// UART RX

`default_nettype none
`timescale 1ns / 1ps

module uart_rx
#(
	parameter CLOCK_FREQ_Mhz = 12,
	parameter BAUD_RATE = 9600,
	parameter PARITY_MODE = 2'b00  // 00 - none, 01 - odd, 10 - even
)
(
	input logic i_Clock,
	input logic i_Data,
	//
	output logic [7:0] o_Data,
	output wire o_Idle,
	output logic o_DataReady,

	output logic [2:0] sm_state,
	output logic [3:0] bit_counter
);
/* verilator lint_off WIDTH */
localparam COUNTER_LIMIT = CLOCK_FREQ_Mhz * 1_000_000 / BAUD_RATE;

logic [$clog2(COUNTER_LIMIT) - 1:0] counter;
//logic [2:0] bit_counter;

localparam s_IDLE = 3'b000;
localparam s_WORKING = 3'b001;
localparam s_PARITY = 3'b010;
localparam s_STOP = 3'b011;

//logic [2:0] sm_state = s_IDLE;
//sm_state = s_IDLE;

logic prev_idle_data = 1;

assign o_Idle = sm_state == s_IDLE;

logic input_temp = 1;
logic input_sync = 1;

// Double-register the incoming data.
// This allows it to be used in the UART RX Clock Domain.
// (It removes problems caused by metastability)
always @(posedge i_Clock) begin
	input_temp <= i_Data;
	input_sync <= input_temp;
end

always @(posedge i_Clock) begin

	case (sm_state)

	s_IDLE: begin
		if (input_sync == 0 && prev_idle_data == 1) begin
			// start bit
			o_Data <= 0;
			o_DataReady <= 0;
			counter <= COUNTER_LIMIT / 2;  // wait a half
			bit_counter <= 0;
			sm_state <= s_WORKING;
		end
		prev_idle_data <= input_sync;
	end

	s_WORKING: begin
		if (counter == 0) begin
			counter <= COUNTER_LIMIT;
			if (bit_counter == 9) begin
				sm_state <= (PARITY_MODE != 0) ? s_PARITY : s_STOP;
			end
			else begin
				o_Data <= (o_Data >> 1) | {input_sync, 7'b0};
				bit_counter <= bit_counter + 1;
			end
		end
		else
			counter <= counter - 1;
	end
	
	s_PARITY: begin
		if (counter == 0) begin
			//TODO: check parity bit
			//counter <= 0;
			//o_Data <= (^rx_buffer ^ PARITY_MODE[0]);
			counter <= COUNTER_LIMIT;
			sm_state <= s_STOP;
		end
		else
			counter <= counter - 1;
	end
	
	s_STOP: begin
		prev_idle_data <= input_sync;
		if (counter == 0) begin
			//TODO: check stop bit
			o_DataReady <= 1;
			sm_state <= s_IDLE;
		end
		else
			counter <= counter - 1;
	end
	
	default: begin
		sm_state <= s_IDLE;
	end
	
	endcase
end
/* verilator lint_on WIDTH */
endmodule
