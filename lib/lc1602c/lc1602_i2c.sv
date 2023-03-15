`default_nettype none
`timescale 1ns / 1ps

module lc1602_i2c #(
	parameter DATA_WIDTH = 8,
	parameter ADDR_WIDTH = 7
)
(
	input i_clk,
	input i_rst,
	input i_enable,
	input i_rw,
	input i_send_2nd_nibble,
	input i_with_pulse,
	input i_data_mode,
	input i_backlight,
	input [DATA_WIDTH-1:0] i_mosi_data,
	input [ADDR_WIDTH-1:0] i_device_addr,
	input logic [15:0] i_divider,
	output [DATA_WIDTH-1:0]	o_miso_data,
	output o_busy,
	inout io_sda,
	inout io_scl
);

logic busy;
logic enable = 0;
logic [DATA_WIDTH-1:0] saved_mosi_data;

logic [DATA_WIDTH-1:0] mosi_data;

/* verilator lint_off PINCONNECTEMPTY */
i2c_master #(.DATA_WIDTH(DATA_WIDTH), .REG_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH), .SEND_REG(0)) 
        i2c_master_inst(
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_enable(enable),
            .i_rw(i_rw),
            .i_mosi_data(mosi_data),
            .i_reg_addr(),
            .i_device_addr(i_device_addr),
            .i_divider(i_divider),
            .o_miso_data(o_miso_data),
            .o_busy(busy),
            .io_sda(io_sda),
            .io_scl(io_scl)
        );
/* verilator lint_on PINCONNECTEMPTY */

localparam ONE_USEC = 12; // CLK / 1M

logic [9:0] wait_counter;
logic [9:0] wait_limit;

enum {S_IDLE, S_SEND_HI_0, S_SEND_HI_1, S_SEND_HI_2, S_SEND_LO_0, S_SEND_LO_1, S_SEND_LO_2, S_END} sm_state;

assign o_busy = busy || (sm_state != S_IDLE);

always @(posedge i_clk) begin
	if (busy)
		enable <= 0;
	else begin
		wait_counter <= wait_counter + 1;
		case (sm_state)
			S_IDLE: begin
				if (i_enable && !o_busy) begin
					saved_mosi_data <= i_mosi_data;
					if (i_with_pulse)
						sm_state <= S_SEND_HI_0;
					else begin
						enable <= 1;
						mosi_data <= i_mosi_data;
					end
				end
			end

			S_SEND_HI_0: begin
				mosi_data <= saved_mosi_data & 8'hf0 | (i_data_mode ? 8'b1 : 8'b0) | (i_backlight ? 8'h08 : 8'b0);  // Rs + Backlight
				wait_counter <= 0;
				wait_limit <= ONE_USEC * 10;
				enable <= 1;
				sm_state <= S_SEND_HI_1;
			end

			S_SEND_HI_1: begin
				if (wait_counter == wait_limit) begin
					mosi_data <= mosi_data | 8'b100;  // En bit
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 10;
					enable <= 1;
					sm_state <= S_SEND_HI_2;
				end
			end

			S_SEND_HI_2: begin
				if (wait_counter == wait_limit) begin
					mosi_data <= mosi_data & ~8'b100;  // En bit reset
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 50;
					enable <= 1;
					sm_state <= i_send_2nd_nibble ? S_SEND_LO_0 : S_IDLE;
				end
			end

			S_SEND_LO_0: begin
				if (wait_counter == wait_limit) begin
					mosi_data <= { saved_mosi_data[3:0], 4'b0 } | (i_data_mode ? 8'b1 : 8'b0) | (i_backlight ? 8'h08 : 8'b0);  // Rs + backlight
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 10;
					enable <= 1;
					sm_state <= S_SEND_LO_1;
				end
			end

			S_SEND_LO_1: begin
				if (wait_counter == wait_limit) begin
					mosi_data <= mosi_data | 8'b100;  // En bit
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 10;
					enable <= 1;
					sm_state <= S_SEND_LO_2;
				end
			end

			S_SEND_LO_2: begin
				if (wait_counter == wait_limit) begin
					mosi_data <= mosi_data & ~8'b100;  // En bit reset
					wait_counter <= 0;
					wait_limit <= ONE_USEC * 50;
					enable <= 1;
					sm_state <= S_END;
				end
			end

			S_END: begin
				if (wait_counter == wait_limit) begin
					sm_state <= S_IDLE;
				end
			end

			default:
				sm_state <= S_IDLE;
		endcase
	end
end

logic _unused_ok = &{1'b1, enable, saved_mosi_data, i_data_mode, 1'b0};

endmodule
