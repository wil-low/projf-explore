`default_nettype none
`timescale 1ns / 1ps

module top_uart
(
	input CLK, input RX, output TX, output logic [7:0] LED
);

logic [7:0] odata;
wire data_ready;
logic idle, idle_tx;
logic start;
logic prev_data_ready = 0;

//assign LED[6] = 1;
//assign LED[7] = ~RX;

wire [2:0] sm_state, sm_state_tx;
wire [3:0] bit_counter;
wire [2:0] bit_counter_tx;

//assign LED[2:0] = ~sm_state;
//assign LED[5:3] = ~bit_counter[2:0];

uart_rx #(12, 9600, 2'b00) rx (CLK, RX, odata, idle, data_ready, sm_state, bit_counter);

// This is not buffered, receipt more than 1 byte at once causes errors!
uart_tx #(12, 9600, 2'b00) tx (CLK, odata, start, TX, idle_tx, sm_state_tx, bit_counter_tx);

always @(posedge CLK) begin
	prev_data_ready <= data_ready;
	if (data_ready == 1 && prev_data_ready == 0) begin
		start <= 1;
		//if (odata != "\r" && odata != "\n")
		LED <= ~odata;
	end
	else begin
		//LED <= ~0;
		start <= 0;
	end
end

wire _unused_ok = &{1'b1, idle, sm_state, bit_counter, idle_tx, sm_state_tx, bit_counter_tx, 1'b0};

endmodule
