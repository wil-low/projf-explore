// Special circuit for LED drive control TM1638

`default_nettype none
`timescale 1ns / 1ps

module tm1638
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
	input wire i_en,
	input wire [7:0] i_raw_data,

	// shield pins
	output logic o_tm1638_clk,
	inout  wire io_tm1638_data,

	// results
	output logic o_idle
);

localparam INNER_CLOCK_8TH = CLOCK_FREQ_MHz * 2;

logic [$clog2(INNER_CLOCK_8TH) + 4:0] inner_clock;

enum {
	s_IDLE, s_SENDING, s_DONE
} state;

logic [7:0] tx_buffer;
logic [2:0] bit_counter;

logic dio_in;
logic dio_out;

assign o_idle = (state == s_IDLE) && !i_en;

sb_inout io (io_tm1638_data, 1'b1, dio_out, dio_in);

always @(posedge i_clk) begin

	case (state)

	s_IDLE: begin
		o_tm1638_clk <= 0;
		if (i_en) begin
			inner_clock <= INNER_CLOCK_8TH * 8 - 1;
			dio_out <= i_raw_data[0];
			tx_buffer <= i_raw_data;
			bit_counter <= 1;
			state <= s_SENDING;
		end
	end

	s_SENDING: begin
		inner_clock <= inner_clock - 1;
		if (inner_clock == INNER_CLOCK_8TH * 3) begin
			o_tm1638_clk <= 0;
		end
		else if (inner_clock == INNER_CLOCK_8TH * 5) begin
			o_tm1638_clk <= 1;
		end
		else if (inner_clock == 0) begin
			inner_clock <= INNER_CLOCK_8TH * 8 - 1;
			dio_out <= tx_buffer[bit_counter];
			if (bit_counter == 0) begin
				state <= s_IDLE;
			end
			else
				bit_counter <= bit_counter + 1;
		end
	end

	s_DONE: begin
		inner_clock <= inner_clock - 1;
		if (inner_clock == 0)
			state <= s_IDLE;
	end

	default:
		state <= s_IDLE;

	endcase
end

wire _unused_ok = &{1'b1, dio_in, 1'b0};

endmodule
