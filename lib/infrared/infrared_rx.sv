// Infrared RX - NEC protocol

`default_nettype none

`timescale 1ns / 1ps

module infrared_rx
#(
	parameter CLOCK_FREQ_MHZ = 12,
	parameter RX_RATE = 4000
)
(
	input wire i_Clock,
	input wire i_Data,
	//
	output logic [4 * 8 - 1:0] o_Data,
	output logic o_Idle,
	output logic o_DataReady,
	output logic [7:0] o_Trace
);
/* verilator lint_off WIDTH */
localparam COUNTER_LIMIT = CLOCK_FREQ_MHZ * 1_000_000 / RX_RATE;

logic [$clog2(COUNTER_LIMIT):0] counter = COUNTER_LIMIT;
logic [5:0] bit_counter;
logic [7:0] trace = 0;

assign o_Trace = trace;

enum {S_IDLE, S_DATA, S_ERROR} sm_state;

assign o_Idle = /*sampling && counter == 0*/ sm_state == S_IDLE;

logic input_temp = 1;
logic input_sync = 1;
logic prev_input_sync = 1;

logic [5:0] counter_1ms = 0;
logic sampling = 0;

// Double-register the incoming data.
// This allows it to be used in the UART RX Clock Domain.
// (It removes problems caused by metastability)
always @(posedge i_Clock) begin
	input_temp <= i_Data;
	input_sync <= input_temp;

	if (counter == 0) begin
		counter <= COUNTER_LIMIT;
		if (sampling) begin
			if (counter_1ms < 63)
				counter_1ms <= counter_1ms + 1;
			else
				sampling <= 0;
		end
		else begin
			sm_state <= S_IDLE;
			o_DataReady <= 0;
		end
	end
	else
		counter <= counter - 1;

	if (input_sync == 0 && prev_input_sync == 1) begin
		case (sm_state)
			S_IDLE: begin
				if (sampling) begin
					if (counter_1ms > 50) begin
						// start of frame
						bit_counter <= 0;
						o_Data <= 0;
						o_DataReady <= 0;
						sm_state <= S_DATA;
					end
				end
				else
					sampling <= 1;
			end

			S_DATA: begin
				bit_counter <= bit_counter + 1;
				if (counter_1ms > 16)
					sampling <= 0;
				else if (counter_1ms > 6)
					o_Data <= (o_Data << 1) | {31'b0, 1'b1};
				else
					o_Data <= (o_Data << 1);

				if (bit_counter == 31) begin
					trace <= trace + 1;
					o_DataReady <= 1;
					sampling <= 0;
				end
			end
			
			S_ERROR: begin
				sm_state <= S_IDLE;
				bit_counter <= ~0;
				sampling <= 0;
			end

			default: begin
				sm_state <= S_IDLE;
			end

		endcase
			
		counter_1ms <= 0;
	end
	prev_input_sync <= input_sync;
end

/* verilator lint_on WIDTH */
endmodule
