// MK14 cpu SoC

`default_nettype none
`timescale 1ns / 1ps

`include "constants.svh"

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

	input wire ir
`ifdef SIMULATION
	,
	input wire btn_dn,
	input wire btn_up,
	input wire [2:0] btn_addr,
	input wire [2:0] btn_bit
`endif
);

`ifdef SIMULATION
localparam BTN_RELEASE_TIMEOUT_CYCLES = 5;
`else
localparam BTN_RELEASE_TIMEOUT_CYCLES = CLOCK_FREQ_MHZ * 1000 * 50;
`endif

localparam DISPLAY_REFRESH_CYCLES = CLOCK_FREQ_MHZ * 1000 * DISPLAY_REFRESH_MSEC;

logic [$clog2(DISPLAY_REFRESH_CYCLES) - 1: 0] display_refresh_counter;

logic [7:0] data_in;
logic [7:0] data_out;

logic core_en = 1;
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
logic kbd_pressed = 0;
logic [$clog2(BTN_RELEASE_TIMEOUT_CYCLES) - 1: 0] btn_up_counter;

`ifndef SIMULATION
logic ir_idle;
logic ir_data_ready;
logic [4 * 8 - 1:0] ir_data;
logic [7:0] ir_error_code;
logic [7:0] ir_saved_data;

infrared_rx #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ)
)
ir_inst (
	clk, ir, ir_data, ir_idle, ir_data_ready, ir_error_code
);

typedef enum {
	sir_IDLE, sir_PRESSED, sir_HOLD
} IR_STATE;

IR_STATE ir_state = sir_IDLE;

always @(posedge clk) begin
	kbd_write_en <= 0;

	case (ir_state)

	sir_IDLE: begin
		//trace <= {ir_idle, ir_data_ready};
		if (ir_data_ready) begin
			//trace <= trace | 2;
			ir_saved_data <= ir_data[15:8];
			ir_state <= sir_PRESSED;
		end
	end

	sir_PRESSED: begin
		//trace <= trace | 4;
		kbd_write_en <= 1;
		kbd_pressed <= 1;

		case (ir_saved_data)
		8'b1011_1010: begin  // OK => MEM
			kbd_addr <= 3;
			kbd_bit <= 5;
		end
		8'b0111_0000: begin  // Audio => TERM
			kbd_addr <= 7;
			kbd_bit <= 5;
		end
		8'b0011_0010: begin  // Menu => GO
			kbd_addr <= 2;
			kbd_bit <= 5;
		end
		8'b0000_0010: begin  // Exit => ABORT
			kbd_addr <= 4;
			kbd_bit <= 5;
		end
		8'b0101_1000: begin  // 0
			kbd_addr <= 0;
			kbd_bit <= 7;
		end
		8'b1100_1000: begin  // 1
			kbd_addr <= 1;
			kbd_bit <= 7;
		end
		8'b1101_1000: begin  // 2
			kbd_addr <= 2;
			kbd_bit <= 7;
		end
		8'b1110_0000: begin  // 3
			kbd_addr <= 3;
			kbd_bit <= 7;
		end
		8'b1110_1000: begin  // 4
			kbd_addr <= 4;
			kbd_bit <= 7;
		end
		8'b1111_1000: begin  // 5
			kbd_addr <= 5;
			kbd_bit <= 7;
		end
		8'b1100_0000: begin  // 6
			kbd_addr <= 6;
			kbd_bit <= 7;
		end
		8'b0110_1000: begin  // 7
			kbd_addr <= 7;
			kbd_bit <= 7;
		end
		8'b0111_1000: begin  // 8
			kbd_addr <= 0;
			kbd_bit <= 6;
		end
		8'b0100_0000: begin  // 9
			kbd_addr <= 1;
			kbd_bit <= 6;
		end
		8'b0001_0010: begin  // A
			kbd_addr <= 0;
			kbd_bit <= 4;
		end
		8'b0000_1010: begin  // B
			kbd_addr <= 1;
			kbd_bit <= 4;
		end
		8'b0010_1010: begin  // C
			kbd_addr <= 2;
			kbd_bit <= 4;
		end
		8'b0001_1010: begin  // D
			kbd_addr <= 3;
			kbd_bit <= 4;
		end
		8'b0010_0010: begin  // E
			kbd_addr <= 6;
			kbd_bit <= 4;
		end
		8'b0011_1010: begin  // F
			kbd_addr <= 7;
			kbd_bit <= 4;
		end
		default: 
			kbd_write_en <= 0;
		endcase

		btn_up_counter <= BTN_RELEASE_TIMEOUT_CYCLES;
		ir_state <= sir_HOLD;
	end

	sir_HOLD: begin
		//trace <= trace | 8;
		btn_up_counter <= btn_up_counter - 1;
		if (btn_up_counter == 0) begin
			kbd_write_en <= 1;
			kbd_pressed <= 0;
			ir_state <= sir_IDLE;
		end
	end

	default:
		ir_state <= sir_IDLE;
	
	endcase
end
`endif

mmu #(
	.CLOCK_FREQ_MHZ(CLOCK_FREQ_MHZ),
	.ROM_INIT_F(ROM_INIT_F),
	.STD_RAM_INIT_F(STD_RAM_INIT_F),
	.EXT_RAM_INIT_F(EXT_RAM_INIT_F)
)
mmu_inst (
	.clk(clk),
	.core_addr,
	.core_write_en,
	.core_write_data(data_in),
	.core_read_data(data_out),

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

localparam SEG7_COUNT = 8;
localparam SEG7_BASE_ADDR = 'hD00;

tm1638_led_key_memmap
#(
	.CLOCK_FREQ_MHz(CLOCK_FREQ_MHZ),
	.SEG7_COUNT(SEG7_COUNT),
	.LED_COUNT(0),
	.SEG7_BASE_ADDR(SEG7_BASE_ADDR),
	.LED_BASE_ADDR(0)
)
display_inst
(
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
) core_inst (
	.rst_n(rst_n),
	.clk,
	.en(core_en),
	.mem_addr(core_addr),
	.mem_read_data(data_out),
	.mem_write_en(core_write_en),
	.mem_write_data(data_in),
	.trace
);

typedef enum {s_RESET, s_RUNNING
} STATE;

STATE state = s_RESET;

always @(posedge clk) begin
	display_en <= 0;
	if (!rst_n) begin
		state <= s_RESET;
	end
	else begin
		case (state)
		s_RESET: begin
			core_en <= 1;
			display_refresh_counter <= DISPLAY_REFRESH_CYCLES;
			state <= s_RUNNING;
		end
		
		s_RUNNING: begin
			display_refresh_counter <= display_refresh_counter - 1;
			if (display_refresh_counter == 0) begin
				display_refresh_counter <= DISPLAY_REFRESH_CYCLES;
				if (display_idle)
					display_en <= 1;
			end
		end

		default:
			state <= s_RESET;

		endcase
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
