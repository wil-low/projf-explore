// MK14 Memory Management Unit

`default_nettype none
`timescale 1ns / 1ps

module mmu #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter ROM_INIT_F = "",
	parameter STD_RAM_INIT_F = "",
	parameter EXT_RAM_INIT_F = ""
)
(
	input wire clk,
	input wire [15:0] core_addr,
	input wire core_write_en,
	input wire [7:0] core_write_data,
	output logic [7:0] core_read_data,

	input wire [15:0] display_addr,
	output logic [7:0] display_data_out,

	input wire kbd_write_en,
	input wire [15:0] kbd_addr,
	input logic [2:0] kbd_bit,
	input wire kbd_pressed
);

logic [15:0] write_data;
logic [15:0] read_data;

logic [15:0] page;
assign page = core_addr & 'hf00;

logic access_std_ram;
logic access_ext_ram;
logic access_rom;
logic access_disp_kbd;

assign access_std_ram = (page == 'hf00);
assign access_ext_ram = (page == 'hb00);
assign access_rom = (page < 'h800);
assign access_disp_kbd = (page == 'h900 || page == 'hd00);

logic [7:0] std_ram_read_data;
logic [7:0] ext_ram_read_data;
logic [7:0] rom_read_data;
logic [7:0] kbd_read_data;

assign core_read_data = access_std_ram  ? std_ram_read_data : (
						access_ext_ram  ? ext_ram_read_data : (
						access_rom      ?     rom_read_data : (
						access_disp_kbd ?    kbd_read_data : 'h00
)));

bram_sdp #(.WIDTH(8), .DEPTH(256), .INIT_F(STD_RAM_INIT_F))
std_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_std_ram),
	.addr_write(core_addr & 'hff),
	.addr_read(core_addr & 'hff),
	.data_in(core_write_data),
	.data_out(std_ram_read_data)
);

bram_sdp #(.WIDTH(8), .DEPTH(256), .INIT_F(EXT_RAM_INIT_F))
ext_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_ext_ram),
	.addr_write(core_addr & 'hff),
	.addr_read(core_addr & 'hff),
	.data_in(core_write_data),
	.data_out(ext_ram_read_data)
);

bram_sdp #(.WIDTH(8), .DEPTH(512), .INIT_F(ROM_INIT_F))
rom (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_rom),
	.addr_write(),
	.addr_read(core_addr & 'h01ff),
	.data_in(),
	.data_out(rom_read_data)
);

logic [8 * 8 - 1:0] disp = 0;
logic [8 * 8 - 1:0] kbd = {8{8'hff}};

assign display_data_out = disp[8 * ((display_addr & 'h0f) + 1) - 1 -: 8];

always @(posedge clk) begin
	if (access_disp_kbd) begin
		//$display("access_disp_kbd: we %b, addr %h, idx = %d, kbd %h", core_write_en, core_addr, (core_addr & 'h0f), kbd);
		if (core_write_en) begin
			if ((core_addr & 'h0f) <= 'h07)
				disp[8 * ((core_addr & 'h0f) + 1) - 1 -: 8] <= core_write_data;
		end
		else begin
			//$display("idx = %d, kbd %h", (core_addr & 'h0f), kbd);
			if ((core_addr & 'h0f) <= 'h07) begin
				//$display("idx = %d", (core_addr & 'h0f) + 1);
				kbd_read_data <= kbd[8 * ((core_addr & 'h0f) + 1) - 1 -: 8];
			end
		end
	end
	if (kbd_write_en) begin
		//$display("%t, kbd_write_en, addr %d, bit %d, pressed %b", $time, kbd_addr, kbd_bit, kbd_pressed);
		if (kbd_pressed)
			kbd[8 * (kbd_addr + 1) - 1 -: 8] <= kbd[8 * (kbd_addr + 1) - 1 -: 8] & ((1 << kbd_bit) ^ 8'hff);
		else
			kbd[8 * (kbd_addr + 1) - 1 -: 8] <= kbd[8 * (kbd_addr + 1) - 1 -: 8] | (1 << kbd_bit);
	end
end

endmodule
