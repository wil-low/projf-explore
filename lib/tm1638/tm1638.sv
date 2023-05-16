// Special circuit for LED drive control TM1638

`default_nettype none
`timescale 1ns / 1ps

module tm1638
#(
	parameter CLOCK_FREQ_MHz = 12
)
(
	input wire i_clk,
	input wire i_write_en,
	input wire [7:0] i_raw_data,

	input wire i_read_en,
	output logic [7:0] o_btn_state,

	// shield pins
	output logic o_tm1638_clk,
	inout  wire io_tm1638_data,

	// results
	output logic o_probe,
	output logic o_idle
);

localparam INNER_CLOCK_8TH = CLOCK_FREQ_MHz;

logic [$clog2(INNER_CLOCK_8TH) + 4:0] inner_clock;

enum {
	s_IDLE, s_WRITE, s_READ, s_READ_STEP
} state;

logic [7:0] buffer;
logic [2:0] bit_counter;
logic [1:0] read_counter;

logic dio_in;
logic dio_out;
logic dio_write_en;

assign o_idle = (state == s_IDLE) && !i_write_en && !i_read_en;
assign o_probe = o_idle;
sb_inout io (io_tm1638_data, dio_write_en, dio_out, dio_in);

always @(posedge i_clk) begin
	//o_probe <= 0;
	case (state)

	s_IDLE: begin
		o_tm1638_clk <= 0;
		if (i_write_en) begin
			//o_probe <= 1;
			dio_write_en <= 1;
			inner_clock <= INNER_CLOCK_8TH * 8 - 1;
			dio_out <= i_raw_data[0];
			buffer <= i_raw_data;
			bit_counter <= 1;
			state <= s_WRITE;
		end
		else if (i_read_en) begin
			dio_write_en <= 0;
			o_btn_state <= 0;
			buffer <= 0;
			inner_clock <= INNER_CLOCK_8TH * 8 - 1;
			bit_counter <= 0;
			read_counter <= 3;
			state <= s_READ;
		end
		//else
		//	$display("%t o_btn_state3 %b", $time, o_btn_state);
	end

	s_WRITE: begin
		inner_clock <= inner_clock - 1;
		if (inner_clock == INNER_CLOCK_8TH * 3) begin
			o_tm1638_clk <= 0;
		end
		else if (inner_clock == INNER_CLOCK_8TH * 5) begin
			o_tm1638_clk <= 1;
		end
		else if (inner_clock == 0) begin
			inner_clock <= INNER_CLOCK_8TH * 8 - 1;
			dio_out <= buffer[bit_counter];
			if (bit_counter == 0)
				state <= s_IDLE;
			else
				bit_counter <= bit_counter + 1;
		end
	end

	s_READ: begin
		inner_clock <= inner_clock - 1;
		if (inner_clock == INNER_CLOCK_8TH * 3) begin
			o_tm1638_clk <= 0;
		end
		else if (inner_clock == INNER_CLOCK_8TH * 5) begin
			o_tm1638_clk <= 1;
		end
		else if (inner_clock == INNER_CLOCK_8TH * 4) begin
			$display("%t bit_counter %d", $time, bit_counter);
			buffer[bit_counter] <= dio_in;
		end
		else if (inner_clock == 0) begin
			inner_clock <= INNER_CLOCK_8TH * 8 - 1;
			if (bit_counter == 7) begin
				o_btn_state <= o_btn_state >> 1;
				state <= s_READ_STEP;
			end
			else
				bit_counter <= bit_counter + 1;
		end
	end

	s_READ_STEP: begin
		$display("%t o_btn_state %b", $time, o_btn_state);
		o_btn_state[3] <= buffer[0];
		o_btn_state[7] <= buffer[4];
		read_counter <= read_counter - 1;
		bit_counter <= 0;
		state <= read_counter == 0 ? s_IDLE : s_READ;
	end

	default:
		state <= s_IDLE;

	endcase
end

wire _unused_ok = &{1'b1, dio_in, 1'b0};

endmodule
