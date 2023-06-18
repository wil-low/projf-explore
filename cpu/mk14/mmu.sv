// MK14 Memory Management Unit

`default_nettype none
`timescale 1ns / 1ps

module mmu #(
	parameter CLOCK_FREQ_MHZ = 50,	// clock frequency == ticks in 1 microsecond
	parameter ROM_INIT_F = "",
	parameter STD_RAM_INIT_F = "",
	parameter EXT_RAM_INIT_F = "",
	parameter VDU_RAM_INIT_F = "",
	parameter VDU_BASE_ADDR = 'h0200,
	parameter LED_BASE_ADDR = 0
)
(
	input wire clk,
	input wire [15:0] core_addr,
	input wire core_write_en,
	input wire [7:0] core_write_data,
	output logic [7:0] core_read_data,

	input wire display_read_en,
	input wire [15:0] display_addr,
	output logic [7:0] display_data_out,

	input wire kbd_write_en,
	input wire [2:0] kbd_addr,
	input wire [2:0] kbd_bit,
	input wire kbd_pressed,

	input wire vdu_read_en,
	input wire [15:0] vdu_addr,
	output logic [7:0] vdu_data_out
);

logic [15:0] write_data;
logic [15:0] read_data;

logic [15:0] page;
assign page = core_addr & 'hf00;

logic access_rom;
logic access_std_ram;
logic access_ext_ram;
logic access_disp_kbd;
logic access_rv0_ram;
logic access_rv1_ram;

assign access_rom = (page < 'h200);
assign access_std_ram = (page == 'hf00);
assign access_ext_ram = (page == 'hb00);
assign access_disp_kbd = (page == 'h900 || page == 'hd00);
assign access_rv0_ram = (page >= VDU_BASE_ADDR && page < 'h800);
assign access_rv1_ram = (page >= 'h1200 && page < 'h1800);

logic [7:0] rom_read_data;
logic [7:0] std_ram_read_data;
logic [7:0] ext_ram_read_data;
logic [7:0] kbd_read_data;
logic [7:0] rv0_ram_read_data;
logic [7:0] rv1_ram_read_data;

assign core_read_data =
	access_std_ram  ? std_ram_read_data : (
	access_ext_ram  ? ext_ram_read_data : (
	access_rom      ?     rom_read_data : (
	access_rv0_ram  ? rv0_ram_read_data : (
	access_rv1_ram  ? rv1_ram_read_data : (
	access_disp_kbd ?    kbd_read_data : 'h00
)))));

bram_sdp #(
	.WIDTH(8), .DEPTH(256), .INIT_F(STD_RAM_INIT_F)
)
std_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_std_ram),
	.addr_write(core_addr & 'hff),
	.addr_read(core_addr & 'hff),
	.data_in(core_write_data),
	.data_out(std_ram_read_data)
);

bram_sdp #(
	.WIDTH(8), .DEPTH(256), .INIT_F(EXT_RAM_INIT_F)
)
ext_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_ext_ram),
	.addr_write(core_addr & 'hff),
	.addr_read(core_addr & 'hff),
	.data_in(core_write_data),
	.data_out(ext_ram_read_data)
);

bram_sqp #(
	.WIDTH(8), .DEPTH(1536), .INIT_F(VDU_RAM_INIT_F)
)
realview_page0_ram (
	.clk(clk),

	.we0(core_write_en && access_rv0_ram),
	.addr_write0((core_addr & 'h7ff) - VDU_BASE_ADDR),
	.addr_read0((core_addr & 'h7ff) - VDU_BASE_ADDR),
	.data_in0(core_write_data),
	.data_out0(rv0_ram_read_data),

	.we1(0),
	.addr_write1(),
	.addr_read1((vdu_addr & 'h7ff) - VDU_BASE_ADDR),
	.data_in1(),
	.data_out1(vdu_data_out)
);

bram_sdp #(
	.WIDTH(8), .DEPTH(1536), .INIT_F(EXT_RAM_INIT_F)
)
realview_page1_ram (
	.clk_write(clk),
	.clk_read(clk),

	.we(core_write_en && access_rv1_ram),
	.addr_write((core_addr & 'h1fff) - 'h1200),
	.addr_read((core_addr & 'h1fff) - 'h1200),
	.data_in(core_write_data),
	.data_out(rv1_ram_read_data)
);

bram_sdp #(
	.WIDTH(8), .DEPTH(512), .INIT_F(ROM_INIT_F)
)
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
// after 1 read a Seg7 digit is cleared (auto-dim)
logic [7:0] seg_on = 0;

logic [7:0] leds = 0;

logic [8 * 8 - 1:0] kbd = {8{8'hff}};

always @(posedge clk) begin
	if (access_disp_kbd) begin
		//$display("access_disp_kbd: we %b, addr %h, idx = %d, kbd %h", core_write_en, core_addr, (core_addr & 'h0f), kbd);
		if (core_write_en) begin
			if (core_addr == LED_BASE_ADDR)
				leds <= core_write_data;
			else if ((core_addr & 'h0f) <= 'h07) begin
				disp[8 * ((core_addr & 'h0f) + 1) - 1 -: 8] <= core_write_data;
				seg_on[core_addr & 'h0f] <= 1;
				//$display("Disp: %h", disp);
			end
		end
		else begin
			if (kbd[8 * ((core_addr & 'h0f) + 1) - 1 -: 8] != 8'hff)
				$display("kbd_out %h", kbd[8 * ((core_addr & 'h0f) + 1) - 1 -: 8]);
			if ((core_addr & 'h0f) <= 'h07)
				kbd_read_data <= kbd[8 * ((core_addr & 'h0f) + 1) - 1 -: 8];
		end
	end

	if (kbd_write_en) begin
		//$display("%t, kbd_write_en, addr %d, bit %d, pressed %b", $time, kbd_addr, kbd_bit, kbd_pressed);
		if (kbd_pressed)
			kbd[8 * (kbd_addr + 1) - 1 -: 8] <= kbd[8 * (kbd_addr + 1) - 1 -: 8] & ((1 << kbd_bit) ^ 8'hff);
		else
			kbd[8 * (kbd_addr + 1) - 1 -: 8] <= kbd[8 * (kbd_addr + 1) - 1 -: 8] | (1 << kbd_bit);
	end

	if (display_read_en) begin
		if (display_addr == LED_BASE_ADDR)
			display_data_out <= leds;
		else begin
			if (seg_on[display_addr & 'h0f]) begin
				display_data_out <= disp[8 * ((display_addr & 'h0f) + 1) - 1 -: 8];
				seg_on[display_addr & 'h0f] <= 0;
			end
			else
				display_data_out <= 0;
		end
	end
end

endmodule
