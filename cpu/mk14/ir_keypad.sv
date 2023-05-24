// MK14 Infrared Remote as Keypad

`default_nettype none
`timescale 1ns / 1ps

module ir_keypad #(
	parameter CLOCK_FREQ_MHZ = 50	// clock frequency == ticks in 1 microsecond
)
(
	input wire logic clk,
	input wire logic en,
	input wire ir,

	output logic kbd_write_en,
	output logic [2:0] kbd_addr,
	output logic [2:0] kbd_bit,
	output logic kbd_pressed,

	output logic soft_reset
);

`ifdef SIMULATION
localparam BTN_RELEASE_TIMEOUT_CYCLES = 5;
`else
localparam BTN_RELEASE_TIMEOUT_CYCLES = CLOCK_FREQ_MHZ * 1000 * 50;
`endif

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
	soft_reset <= 1;

	case (ir_state)

	sir_IDLE: begin
		if (en && ir_data_ready) begin
			ir_saved_data <= ir_data[15:8];
			ir_state <= sir_PRESSED;
		end
	end

	sir_PRESSED: begin
		kbd_write_en <= 1;
		kbd_pressed <= 1;

		case (ir_saved_data)
		8'b1100_0010: begin  // Mute => RESET
			soft_reset <= 0;
		end
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

endmodule
