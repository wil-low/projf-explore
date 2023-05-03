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
	output logic o_tm1638_stb,
	inout  wire io_tm1638_data,

	// results
	output logic o_idle
);

localparam INNER_CLOCK_SEMI = CLOCK_FREQ_MHz * 14; // 3

logic [$clog2(INNER_CLOCK_SEMI) + 1:0] inner_clock = INNER_CLOCK_SEMI * 2;

localparam s_IDLE = 2'b00;
localparam s_SENDING = 2'b01;
localparam s_DONE = 2'b10;

logic [1:0] sm_state = s_IDLE;

logic [7:0] tx_buffer;
logic [2:0] bit_counter;

logic dio_in;
logic dio_out;

sb_inout io (io_tm1638_data, 1'b1, dio_out, dio_in);

always @(posedge i_clk) begin

	case (sm_state)

	s_IDLE: begin
		o_tm1638_stb <= 1;
		o_idle <= 1;
		o_tm1638_clk <= 0;
		if (i_en) begin
			o_tm1638_stb <= 0;
			o_tm1638_clk <= 1;
			inner_clock <= INNER_CLOCK_SEMI * 2 - 1;
			dio_out <= i_raw_data[0];
			tx_buffer <= i_raw_data;
			bit_counter <= 1;
			o_idle <= 0; // busy
			sm_state <= s_SENDING;
		end
	end

	s_SENDING: begin
		inner_clock <= inner_clock - 1;
		if (inner_clock == INNER_CLOCK_SEMI) begin
			o_tm1638_clk <= 0;
		end
		else if (inner_clock == 0) begin
			dio_out <= tx_buffer[bit_counter];
			o_tm1638_clk <= 1;
			if (bit_counter == 7) begin
				sm_state <= s_DONE;
			end
			else
				bit_counter <= bit_counter + 1;
			inner_clock <= INNER_CLOCK_SEMI * 2 - 1;
		end
	end

	s_DONE: begin
		inner_clock <= inner_clock - 1;
		if (inner_clock == INNER_CLOCK_SEMI)
			o_tm1638_stb <= 1;
		else if (inner_clock == 0)
			sm_state <= s_IDLE;
	end

	default:
		sm_state <= s_IDLE;

	endcase
end

wire _unused_ok = &{1'b1, dio_in, 1'b0};

endmodule
