// MK14 Memory Management Unit

`default_nettype none
`timescale 1ns / 1ps

module mmu #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter ROM_INIT_F = "",
	parameter STD_RAM_INIT_F = "",
	parameter EXT_RAM_INIT_F = "",
	parameter DISP_KBD_INIT_F = ""
)
(
	input wire clk,
	input wire [15:0] core_addr,
	input wire core_write_en,
	input wire [7:0] core_write_data,
	output logic [7:0] core_read_data,

	input wire [15:0] display_addr,
	output logic [7:0] display_data_out
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
logic [7:0] keyb_read_data;

assign core_read_data = access_std_ram  ? std_ram_read_data : (
						access_ext_ram  ? ext_ram_read_data : (
						access_rom      ?     rom_read_data : (
						access_disp_kbd ?    keyb_read_data : 'h00
)));

bram_sdp #(.WIDTH(8), .DEPTH(256), .INIT_F(STD_RAM_INIT_F))
std_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_std_ram),
	.addr_write(core_addr & 'hf00),
	.addr_read(core_addr & 'hf00),
	.data_in(core_write_data),
	.data_out(std_ram_read_data)
);

bram_sdp #(.WIDTH(8), .DEPTH(256), .INIT_F(EXT_RAM_INIT_F))
ext_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_ext_ram),
	.addr_write(core_addr & 'hf00),
	.addr_read(core_addr & 'hf00),
	.data_in(core_write_data),
	.data_out(ext_ram_read_data)
);

bram_sdp #(.WIDTH(8), .DEPTH(256), .INIT_F(ROM_INIT_F))
rom (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_rom),
	.addr_write(),
	.addr_read(core_addr & 'h01ff),
	.data_in(),
	.data_out(rom_read_data)
);

bram_sqp #(.WIDTH(8), .DEPTH(16), .INIT_F(DISP_KBD_INIT_F))
disp_kbd (
	.clk(clk),

	.we0(core_write_en && access_disp_kbd && (core_addr & 'h0f) <= 'h07),
	.addr_write0(core_addr & 'h07),
	.addr_read0(core_addr & 'h07),
	.data_in0(core_write_data),
	.data_out0(keyb_read_data),

	.we1(0),
	.addr_write1(),
	.addr_read1(display_addr & 'h07),
	.data_in1(),
	.data_out1(display_data_out)
);

endmodule
