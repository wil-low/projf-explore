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
	output logic [2:0] o_error_code,	// error code
	output logic o_parse_complete		// EOF reached without errors
);

logic [2:0] counter;  // input byte counter
logic [7:0] data_len;
logic [7:0] data_type;
logic [7:0] crc;
logic [7:0] data_sum;

logic [7:0] from_hex;

typedef enum {
	s_IDLE, s_DATALEN, s_ADDRESS, s_TYPE, s_DATA, s_WAIT_OUTPUT, s_CRC, s_CRC_CHECK
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
		from_hex = i_data + 10 - "a";
	"A", "B", "C", "D", "E", "F":
		from_hex = i_data + 10 - "A";
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

always @(posedge i_clk) begin
	o_data_valid <= 0;
	o_error_code <= e_OK;
	o_parse_complete <= 0;

	if (i_en)
		$display("i_data = %s", i_data);

	case (state)
	s_IDLE: if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else if (from_hex == DATA_BEGIN) begin
			$display("begin");
			state <= s_DATALEN;
			counter <= 2;
			data_len <= 0;
			data_type <= 0;
		end
	end

	s_DATALEN: if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else if (from_hex[7:4]) begin
			o_error_code <= e_DATA_OUT_OF_ORDER;
			state <= s_IDLE;
		end
		else begin
			data_len <= {data_len[3:0], from_hex[3:0]};
			if (counter == 1) begin
				state <= s_ADDRESS;
				counter <= 4;
				o_addr <= 0;
				data_sum <= 0;
			end
			else
				counter <= counter - 1;
		end
	end

	s_ADDRESS: if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else if (from_hex[7:4]) begin
			o_error_code <= e_DATA_OUT_OF_ORDER;
			state <= s_IDLE;
		end
		else begin
			o_addr <= {o_addr[11:0], from_hex[3:0]};
			if (counter == 1) begin
				$display("data_len %h", data_len);
				data_sum <= data_sum + data_len;
				//$display("data_sum %h + data_len %h", data_sum, data_len);
				state <= s_TYPE;
				counter <= 2;
			end
			else
				counter <= counter - 1;
		end
	end

	s_TYPE: if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else if (from_hex[7:4]) begin
			o_error_code <= e_DATA_OUT_OF_ORDER;
			state <= s_IDLE;
		end
		else begin
			data_type <= {data_type[3:0], from_hex[3:0]};
			if (counter == 1) begin
				$display("address %h", o_addr);
				$display("data_type %d", {data_type[3:0], from_hex[3:0]});
				data_sum <= data_sum + o_addr[15:8] + o_addr[7:0];
				//$display("data_sum %h + addr %h and %h", data_sum, o_addr[15:8], o_addr[7:0]);
				state <= s_DATA;
				counter <= 2;
				o_data <= 0;
				crc <= 0;
				if ({data_type[3:0], from_hex[3:0]} == 1)  // EOF
					state <= s_CRC;
			end
			else
				counter <= counter - 1;
		end
	end

	s_DATA: if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else
		case (data_type)
		0: begin  // binary data
			o_data <= {o_data[3:0], from_hex[3:0]};
			if (counter == 1) begin
				o_data_valid <= 1;
				state <= s_WAIT_OUTPUT;
				$display("wait");
			end
			else
				counter <= counter - 1;
		end

		default: begin
			o_error_code <= e_DATA_TYPE_UNSUPPORTED;
			state <= s_IDLE;
		end
		endcase
	end

	s_WAIT_OUTPUT: begin
		counter <= 2;
		o_addr <= o_addr + 1;
		data_sum <= data_sum + o_data;
		$display("data_valid addr %h, o_data %h", o_addr, o_data);
		//$display("data_sum %h + o_data %h", data_sum, o_data);
		data_len <= data_len - 1;
		if (data_len == 1) begin
			state <= s_CRC;
			$display("go to CRC state");
		end
		else
			state <= s_DATA;
	end

	s_CRC: if (i_en) begin
		if (from_hex == DATA_INVALID) begin
			o_error_code <= e_DATA_INVALID;
			state <= s_IDLE;
		end
		else if (from_hex[7:4]) begin
			o_error_code <= e_DATA_OUT_OF_ORDER;
			state <= s_IDLE;
		end
		else begin
			crc <= {crc[3:0], from_hex[3:0]};
			if (counter == 1) begin
				state <= s_CRC_CHECK;
				$display("go to CRLF state");
			end
			else
				counter <= counter - 1;
		end
	end

	s_CRC_CHECK: begin
		$display("data_sum %h + data_type %h + crc %h", data_sum, data_type, crc);
		if ((data_sum + data_type + crc) & 'hff) begin
			o_error_code <= e_CRC_MISMATCH;
		end
		$display("Line OK, wait for ':'\n");
		if (data_type == 1)
			o_parse_complete <= 1;
		state <= s_IDLE;
	end

	default:
		state <= s_IDLE;

	endcase
end

endmodule
