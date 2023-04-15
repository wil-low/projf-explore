`default_nettype none
`timescale 1ns / 1ps

`include "instructions.svh"

module mc14500b
(
	input logic RST,
	input logic X2,
	input logic [3:0] INSTR,
	input logic DATA_IN,
	output logic DATA_OUT,
	output logic X1,
	output logic RR,
	output logic WRITE,
	output logic JMP,
	output logic RTN,
	output logic FLG0,
	output logic FLGF
);

logic skz, ien, oen;

logic [3:0] saved_instr;

assign X1 = RST | X2;

always @(posedge X2) begin
	saved_instr <= INSTR;
	$display("posedge X2, saved_instr %x, RR %b", INSTR, RR);
end

always @(negedge X2) begin
	if (RST) begin
		{RR, JMP, RTN, FLG0, FLGF, WRITE, skz, ien, oen, DATA_OUT} <= 0;
		$display("RESET");
	end
	else begin
		{JMP, RTN, FLG0, FLGF, WRITE, skz} <= 0;
		if (!JMP && !RTN && !skz) begin
			case (saved_instr)
				`I_NOP0: begin
					FLG0 <= 1;
				end

				`I_LD: begin
					RR <= ien & DATA_IN;
					$display("LD, DATA_IN=%b, RR=%b", DATA_IN, RR);
				end

				`I_LDC: begin
					RR <= ~(ien & DATA_IN);
				end

				`I_AND: begin
					RR <= RR & (ien & DATA_IN);
				end

				`I_ANDC: begin
					RR <= RR & ~(ien & DATA_IN);
				end

				`I_OR: begin
					RR <= RR | (ien & DATA_IN);
				end

				`I_ORC: begin
					RR <= RR | ~(ien & DATA_IN);
				end

				`I_XNOR: begin
					RR <= RR ^ ~(ien & DATA_IN);
				end

				`I_STO: begin
					if (oen) begin
						DATA_OUT <= RR;
						WRITE <= 1;
					end
				end

				`I_STOC: begin
					if (oen) begin
						DATA_OUT <= ~RR;
						WRITE <= 1;
					end
				end

				`I_IEN: begin
					ien <= DATA_IN;
				end

				`I_OEN: begin
					oen <= DATA_IN;
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
			$display("negedge X2, saved_instr %x, RR %b", saved_instr, RR);
		end
		else
			$display("negedge X2, skip instr");
	end

end

logic _unused_ok = &{1'b1, 1'b0};

endmodule
