`define I_NOP0	4'b0000		// 4'h0
`define I_LD	4'b0001		// 4'h1
`define I_LDC	4'b0010		// 4'h2
`define I_AND	4'b0011		// 4'h3
`define I_ANDC	4'b0100		// 4'h4
`define I_OR	4'b0101		// 4'h5
`define I_ORC	4'b0110		// 4'h6
`define I_XNOR	4'b0111		// 4'h7
`define I_STO	4'b1000		// 4'h8
`define I_STOC	4'b1001		// 4'h9
`define I_IEN	4'b1010		// 4'ha
`define I_OEN	4'b1011		// 4'hb
`define I_JMP	4'b1100		// 4'hc   -- Skip next
`define I_RTN	4'b1101		// 4'hd   -- Skip next
`define I_SKZ	4'b1110		// 4'he   -- Skip next if RR == 0
`define I_NOPF	4'b1111		// 4'hf

`define INPUT_RR 4'h0
`define INPUT_1	4'h1
`define INPUT_2	4'h2
`define INPUT_3	4'h3
`define INPUT_4	4'h4
`define INPUT_5	4'h5
`define INPUT_6	4'h6
`define INPUT_7	4'h7

`define OUTPUT_0 4'h0
`define OUTPUT_1 4'h1
`define OUTPUT_2 4'h2
`define OUTPUT_3 4'h3
`define OUTPUT_4 4'h4
`define OUTPUT_5 4'h5
`define OUTPUT_6 4'h6
`define OUTPUT_7 4'h7

`define SCRATCHPAD_0 4'h8
`define SCRATCHPAD_1 4'h9
`define SCRATCHPAD_2 4'ha
`define SCRATCHPAD_3 4'hb
`define SCRATCHPAD_4 4'hc
`define SCRATCHPAD_5 4'hd
`define SCRATCHPAD_6 4'he
`define SCRATCHPAD_7 4'hf
