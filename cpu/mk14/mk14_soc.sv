// MK14 cpu SoC

`default_nettype none
`timescale 1ns / 1ps

module mk14_soc #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter DISPLAY_REFRESH_MSEC = 50,
	parameter ROM_INIT_F = "",
	parameter STD_RAM_INIT_F = "",
	parameter EXT_RAM_INIT_F = ""
)
(
	input wire logic rst_n,
	input wire logic clk,
	output logic [7:0] trace,
	output logic probe,

	output logic o_ledkey_clk,
	output logic o_ledkey_stb,
	inout  wire  io_ledkey_dio,

	input wire ir,

	input wire sin,
	output logic sout,
`ifdef SIMULATION
	input wire btn_dn,
	input wire btn_up,
	input wire [2:0] btn_addr,
	input wire [2:0] btn_bit,
`endif
	input wire rx,
	output logic rx_wait
);

`ifdef SIMULATION
	localparam BTN_RELEASE_TIMEOUT_CYCLES = 5;
	localparam DISPLAY_REFRESH_CYCLES = 5;
	localparam RX_TIMEOUT_CYCLES = 5;
`else
	localparam BTN_RELEASE_TIMEOUT_CYCLES = CLOCK_FREQ_MHZ * 1000 * 50;
	localparam DISPLAY_REFRESH_CYCLES = CLOCK_FREQ_MHZ * 1000 * DISPLAY_REFRESH_MSEC;
	localparam RX_TIMEOUT_CYCLES = CLOCK_FREQ_MHZ * 1000 * 2000;
	localparam RX_EXTEND_CYCLES = CLOCK_FREQ_MHZ * 1000 * 100;
`endif


logic [$clog2(RX_TIMEOUT_CYCLES) - 1: 0] display_refresh_counter;

logic [7:0] core_data_in;
logic [7:0] core_data_out;

logic core_en;
logic [15:0] core_addr;
logic core_write_en;

logic display_en;

logic display_read_en;
logic [15:0] display_addr;
logic [7:0] display_data_out;
logic display_idle;

logic kbd_write_en;
logic [2:0] kbd_addr;
logic [2:0] kbd_bit;
logic kbd_pressed;
logic soft_reset;

ir_keypad #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ)
)
ir_keypad_inst (
	.clk,
	.en(state != s_RX_WAIT),
	.ir,
	.kbd_write_en,
	.kbd_addr,
	.kbd_bit,
	.kbd_pressed,
	.soft_reset
);

logic write_en;
logic [15:0] addr;
logic [7:0] data_in;

assign write_en = rx_wait ? ihex_data_valid : core_write_en;
assign addr = rx_wait ? ihex_addr : core_addr;
assign data_in = rx_wait ? ihex_data : core_data_in;

localparam SEG7_BASE_ADDR	= 'hD00;
localparam LED_BASE_ADDR	= 'hD09;

mmu #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ),
	.ROM_INIT_F(ROM_INIT_F),
	.STD_RAM_INIT_F(STD_RAM_INIT_F),
	.EXT_RAM_INIT_F(EXT_RAM_INIT_F),
	.LED_BASE_ADDR(LED_BASE_ADDR)
)
mmu_inst (
	.clk(clk),
	.core_addr(addr),
	.core_write_en(write_en),
	.core_write_data(data_in),
	.core_read_data(core_data_out),

	.display_read_en,
	.display_addr,
	.display_data_out,

`ifdef SIMULATION
	.kbd_write_en(btn_dn ^ btn_up),
	.kbd_addr(btn_addr),
	.kbd_bit(btn_bit),
	.kbd_pressed(btn_dn)
`else
	.kbd_write_en,
	.kbd_addr,
	.kbd_bit,
	.kbd_pressed
`endif
);

tm1638_led_key_memmap #(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHZ),
	.SEG7_BASE_ADDR(SEG7_BASE_ADDR),
	.LED_BASE_ADDR(LED_BASE_ADDR)
)
display_inst (
	.i_clk(clk),
	.i_en(display_en),

	.o_read_en(display_read_en),
	.o_read_addr(display_addr),
	.i_read_data(display_data_out),

	// shield pins
	.o_tm1638_clk(o_ledkey_clk),
	.o_tm1638_stb(o_ledkey_stb),
	.io_tm1638_data(io_ledkey_dio),

	.probe(probe),
	.o_idle(display_idle)
);

core #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ)
)
core_inst (
	.rst_n(rst_n && soft_reset),
	.clk,
	.en(core_en),
	.mem_addr(core_addr),
	.mem_read_data(core_data_out),
	.mem_write_en(core_write_en),
	.mem_write_data(core_data_in),
	.trace
);

typedef enum {
	s_INIT, s_RX_WAIT, s_SOFT_RESET, s_START, s_RUNNING
} STATE;

STATE state = s_INIT;

assign rx_wait = state == s_RX_WAIT;

always @(posedge clk) begin
	display_en <= 0;
	if (!rst_n) begin
		state <= s_INIT;
	end
	else begin
		case (state)
		s_INIT: begin
			core_en <= 0;
			display_refresh_counter <= RX_TIMEOUT_CYCLES;
			state <= s_RX_WAIT;
		end

		s_RX_WAIT,
		s_SOFT_RESET: begin
			core_en <= 0;
			if (soft_reset) begin
				if (display_refresh_counter == 0)
					state <= s_START;
				else
					display_refresh_counter <= display_refresh_counter - 1;
			end
		end
		
		s_START: begin
			core_en <= 1;
			display_refresh_counter <= DISPLAY_REFRESH_CYCLES;
			state <= s_RUNNING;
		end

		s_RUNNING: begin
			if (!soft_reset) begin
				$display("soft_reset");
				state <= s_SOFT_RESET;
				display_refresh_counter <= DISPLAY_REFRESH_CYCLES;
			end
			else begin
				display_refresh_counter <= display_refresh_counter - 1;
				if (display_refresh_counter == 0) begin
					display_refresh_counter <= DISPLAY_REFRESH_CYCLES;
					if (display_idle)
						display_en <= 1;
				end
			end
		end

		default:
			state <= s_INIT;

		endcase
	end
end

logic [7:0] rx_data;
logic rx_data_valid;

logic [15:0] ihex_addr;
logic [7:0] ihex_data;
logic ihex_idle;
logic ihex_data_valid;
logic [2:0] ihex_error_code;
logic ihex_parse_complete;

uart_rx #(
	.CLK_FRE(CLOCK_FREQ_MHZ),
	.BAUD_RATE(115200)
)
uart_rx_inst (
	.clk,
	.rst_n,
	.rx_data,
	.rx_data_valid,
	.rx_data_ready(rx_wait),
	.rx_pin(rx)
);

intel_hex
intel_hex_inst (
	.i_clk(clk),
	.i_en(rx_data_valid && rx_wait),
	.i_data(rx_data),
	.o_addr(ihex_addr),
	.o_data(ihex_data),
	.o_idle(ihex_idle),
	.o_data_valid(ihex_data_valid),
	.o_error_code(ihex_error_code),
	.o_parse_complete(ihex_parse_complete)
);

endmodule
