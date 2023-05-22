`default_nettype none
`timescale 1ns / 1ps

module intel_hex
(
	input wire i_clk,
	input wire i_en,			  		// data arrived
	input wire [7:0] i_data,			// byte from stream
	output logic [15:0] o_addr,			// target address
	output logic [7:0] o_data,			// output byte
	output logic o_idle,				// idle, waiting for data
	output logic o_data_valid,			// output data ready
	output logic [2:0] o_error_code		// error code
);

logic [2:0] counter;  // input byte counter
logic [7:0] data_len;
logic [7:0] data_counter;
logic [2:0] data_type;
logic [7:0] crc;
logic [7:0] data_sum;

wire [7:0] from_hex;

typedef enum {
	s_IDLE, s_DATALEN, s_ADDRESS, s_TYPE, s_DATA, s_CRC, s_CR, s_LF, s_CHECK_CRC
} STATE;
STATE state;

assign o_idle = (state == s_IDLE) && !i_en;

typedef enum {
	e_OK, e_DATA_INVALID, e_DATA_OUT_OF_ORDER, e_DATA_TYPE_UNSUPPORTED, e_CRC_MISMATCH
} ERRO_CODE;

localparam DATA_BEGIN = 8'h10;
localparam DATA_CR = 8'h20;
localparam DATA_LF = 8'h30;
localparam DATA_INVALID = 8'h40;

always @(*) begin
	case (i_data)
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
		from_hex = i_data - "0";
	"a", "b", "c", "d", "e", "f":
		from_hex = i_data - "0";
	"A", "B", "C", "D", "E", "F":
		from_hex = i_data - "0";
	":":
		from_hex = DATA_BEGIN;
	'h0d:
		from_hex = DATA_CR;
	'h0a:
		from_hex = DATA_LF;
	default:
		from_hex = DATA_INVALID;
	endcase
end

always @(posedge clk) begin
	o_data_valid <= 0;
	o_error_code <= e_OK;

	if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else
			case (state)
			s_IDLE: begin
				if (from_hex == DATA_BEGIN) begin
					state <= s_DATALEN;
					counter <= 2;
					data_len <= 0;
				end
				else begin
					error_code <= e_DATA_OUT_OF_ORDER;
				end 
			end

			s_DATALEN: begin
				if (from_hex[7:4]) begin
					o_error_code <= e_DATA_OUT_OF_ORDER;
					state <= s_IDLE;
				end
				else begin
					data_len <= {data_len[3:0], from_hex[3:0]};
					if (counter == 0) begin
						state <= s_ADDRESS;
						counter <= 4;
						o_addr <= 0;
					end
					else
						counter <= counter - 1;
				end
			end

			s_ADDRESS: begin
				if (from_hex[7:4]) begin
					o_error_code <= e_DATA_OUT_OF_ORDER;
					state <= s_IDLE;
				end
				else begin
					o_addr <= {data_len[11:0], from_hex[3:0]};
					if (counter == 0) begin
						data_sum <= data_sum + data_len;
						state <= s_TYPE;
						counter <= 2;
						data_type <= 0;
					end
					else
						counter <= counter - 1;
				end
			end

			s_TYPE: begin
				if (from_hex[7:4]) begin
					o_error_code <= e_DATA_OUT_OF_ORDER;
					state <= s_IDLE;
				end
				else begin
					data_type <= {data_type[3:0], from_hex[3:0]};
					if (counter == 0) begin
						data_sum <= data_sum + o_addr;
						state <= s_DATA;
						counter <= 2;
						o_data <= 0;
						data_sum <= 0;
						crc <= 0;
					end
					else
						counter <= counter - 1;
				end
			end

			s_DATA: begin
				if (data_counter == 0)
					state <= s_CRC;
				else begin
					case (data_type)
					0: begin  // binary data
						if (counter == 0) begin
							counter <= 2;
							o_data_valid <= 1;
							o_addr <= o_addr + 1;
							data_sum <= data_sum + o_data;
						end
						else begin
							o_data <= {o_data[3:0], from_hex[3:0]};
							counter <= counter - 1;
						end
					end

					1: begin  // end of file
						state <= s_CRC;
					end

					default: begin
						o_error_code <= e_DATA_TYPE_UNSUPPORTED;
						state <= s_IDLE;
					end
					endcase
				end
			end

			s_CRC: begin
				if (from_hex[7:4]) begin
					o_error_code <= e_DATA_OUT_OF_ORDER;
					state <= s_IDLE;
				end
				else begin
					crc <= {crc[3:0], from_hex[3:0]};
					if (counter == 0) begin
						data_sum <= data_sum + crc;
						state <= s_CR;
					end
					else
						counter <= counter - 1;
				end
			end

			s_CR: begin
				if (from_hex != DATA_CR) begin
					o_error_code <= e_DATA_OUT_OF_ORDER;
					state <= s_IDLE;
				end
				else
					state <= s_LF;
			end

			s_LF: begin
				if (from_hex != DATA_CR) begin
					o_error_code <= e_DATA_OUT_OF_ORDER;
					state <= s_IDLE;
				end
				else
					state <= s_CHECK_CRC;
			end

			s_CHECK_CRC: begin
				o_error_code <= data_sum ? e_CRC_MISMATCH : e_OK;
				state <= s_IDLE;
			end

			default:
				state <= s_IDLE;

			endcase
		end
	end
end

endmodule
