`default_nettype none
`timescale 1ns / 1ps

module top_uart(
	input logic CLK,
	input logic RX,
	output logic TX,
	//output logic RX_COPY,
	//output logic TX_COPY,
	output logic [7:0] LED,
	output logic LED1,
	output logic LED2,
	output logic LED3,
	output logic LED4
);

parameter CLK_FRE = 12;//Mhz
parameter BAUD_RATE = 9600;

//// Reset emulation for ice40
logic [7:0] reset_counter = 0;
logic RST_N = &reset_counter;

always @(posedge CLK) begin
	if (!RST_N)
		reset_counter <= reset_counter + 1;
end

logic[7:0]                         tx_data;
logic[7:0]                         tx_str;
logic                              tx_data_valid;
wire                             tx_data_ready;
logic[7:0]                         tx_cnt;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
wire                             rx_data_ready;
logic[31:0]                        wait_cnt;
logic[3:0]                         state;

localparam WIDTH = 8;
logic push_en = 0;					// push enable (port a)

logic pop_en = 0;			  		// pop enable (port a)
wire [WIDTH-1:0] pop_data; 			// data to pop (port b)

logic full;							// buffer is full
logic empty;						// buffer is empty

//assign RX_COPY = RX;
//assign TX_COPY = TX;

uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(BAUD_RATE)
) uart_rx_inst
(
	.clk                        (CLK                      ),
	.rst_n                      (RST_N                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (RX                  )
);

// buffer (between RX to TX)
fifo #(WIDTH, 256)
fifo_inst(.clk(CLK), .rst_n(RST_N), .push_en, .push_data(rx_data), .pop_en, .pop_data, .full, .empty);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(BAUD_RATE)
) uart_tx_inst
(
	.clk                        (CLK                      ),
	.rst_n                      (RST_N                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (TX                  )
);

assign LED1 = ~full;
assign LED2 = ~empty;
assign LED3 = ~push_en;
assign LED4 = ~pop_en;

assign rx_data_ready = 1'b1; //always can receive data

logic [3:0] counter = 1;

always @(posedge CLK) begin
	push_en <= 0;
	pop_en <= 0;
	if (tx_data_valid && tx_data_ready)
		tx_data_valid <= 1'b0;
	if (rx_data_valid) begin
		LED <= ~rx_data;
		push_en <= 1;
	end
	else if (!empty && tx_data_ready) begin
		if (counter == 0) begin
			LED <= ~pop_data;
			tx_data <= pop_data;
			pop_en <= 1;
			tx_data_valid <= 1;
		end
		counter <= counter + 1;
	end
end

endmodule