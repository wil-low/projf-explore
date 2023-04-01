`default_nettype none
`timescale 1ns / 1ps

`include "instructions.sv"

module mc14500b
(
	input RST,
	input X2,
	input [3:0] INSTR,
	inout logic DATA,
	output logic X1,
	output logic RR,
	output logic WRITE,
	output logic JMP,
	output logic RTN,
	output logic FLG0,
	output logic FLGF
);

logic skz, ien, oen;
logic data_oen = 0, data_out, data_in;

sb_inout inout_inst(DATA, data_oen, data_out, data_in);

assign X1 = RST | X2;

always @(posedge X2) begin
	if (RST) begin
		{RR, JMP, RTN, FLG0, FLGF, WRITE, skz, ien, oen, data_out} <= 0;
	end
	else begin
		{JMP, RTN, FLG0, FLGF, WRITE, skz} <= 0;
		if (!RTN && !skz) begin
			case (INSTR)
				`I_NOP0: begin
					FLG0 <= 1;
				end

				`I_LD: begin
					RR <= ien & data_in;
					$display("LD, DATA=%b, data_in=%b, RR=%b", DATA, data_in, RR);
				end

				`I_LDC: begin
					RR <= ien & ~data_in;
				end

				`I_AND: begin
					RR <= RR & (ien & data_in);
				end

				`I_ANDC: begin
					RR <= RR & (ien & ~data_in);
				end

				`I_OR: begin
					RR <= RR | (ien & data_in);
				end

				`I_ORC: begin
					RR <= RR | (ien & ~data_in);
				end

				`I_XNOR: begin
					RR <= RR ^ (ien & ~data_in);
				end

				`I_STO: begin
					if (oen) begin
						data_out <= RR;
						data_oen <= 1;
						WRITE <= 1;
					end
				end

				`I_STOC: begin
					if (oen) begin
						data_out <= ~RR;
						data_oen <= 1;
						WRITE <= 1;
					end
				end

				`I_IEN: begin
					ien <= data_in;
				end

				`I_OEN: begin
					oen <= data_in;
				end

				`I_JMP: begin
					JMP <= 1;
				end

				`I_RTN: begin
					RTN <= 1;
				end

				`I_SKZ: begin
					skz <= RR == 0;
				end

				`I_NOPF: begin
					FLGF <= 1;
				end
			endcase
		end
	end
end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
