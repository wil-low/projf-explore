`ifndef CONSTANTS_SVH

`define CONSTANTS_SVH

// == Memory reference ==
`define i_LD  8'b11000???
`define i_ST  8'b11001???
`define i_AND 8'b11010???
`define i_OR  8'b11011???
`define i_XOR 8'b11100???
`define i_DAD 8'b11101???
`define i_ADD 8'b11110???
`define i_CAD 8'b11111???

// == Transfer of control ==
`define i_JMP 8'b100100??
`define i_JP  8'b100101??
`define i_JZ  8'b100110??
`define i_JNZ 8'b100111??

// == Pointer register move ==
`define i_XPAL 8'b001100??
`define i_XPAH 8'b001101??
`define i_XPPC 8'b001111??

// == Memory increment/decrement ==
`define i_ILD  8'b101010??
`define i_DLD  8'b101110??

// == Immediate ==
`define i_LDI 8'hc4
`define i_ANI 8'hd4
`define i_ORI 8'hdc
`define i_XRI 8'he4
`define i_DAI 8'hec
`define i_ADI 8'hf4
`define i_CAI 8'hfc

// == Extension Register ==
`define i_LDE 8'h40
`define i_XAE 8'h01
`define i_ANE 8'h50
`define i_ORE 8'h58
`define i_XRE 8'h60
`define i_DAE 8'h68
`define i_ADE 8'h70
`define i_CAE 8'h78

// == Shift Rotate Serial IO ==
`define i_SIO 8'h19
`define i_SR  8'h1c
`define i_SRL 8'h1d
`define i_RR  8'h1e
`define i_RRL 8'h1f

// == Double Byte Miscellaneous ==
`define i_DLY 8'h8f

// == Single Byte Miscellaneous ==
`define i_HALT 8'h00
`define i_CCL  8'h02
`define i_SCL  8'h03
`define i_DINT 8'h04
`define i_IEN  8'h05
`define i_CSA  8'h06
`define i_CAS  8'h07
`define i_NOP  8'h08

`endif
