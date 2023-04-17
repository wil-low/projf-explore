`ifndef CONSTANTS_SVH

`define CONSTANTS_SVH

// error codes
`define ERR_INVALID 'h100   // invalid instruction code
`define ERR_COLD    'h101   // cold start
`define ERR_ALIGN   'h102   // alignment error
`define ERR_INVMEM  'h103   // invalid memory location
`define ERR_DSINDEX 'h104   // invalid data stack index
`define ERR_DSFULL  'h105   // data stack overflow
`define ERR_DSEMPTY 'h106   // data stack underflow
`define ERR_CSFULL  'h107   // call stack overflow
`define ERR_CSEMPTY 'h108   // call stack underflow
`define ERR_CALC    'h109   // arithmetic error (eg. division by 0)
`define ERR_ECST    'h10a   // error in conditional structure
                            // ELSE or ENDIF without an opening IF
                            // UNTIL without an opening REPEAT
`define ERR_DBLENT  'h10b   // double entering error
`define ERR_NOENT   'h10c   // LEAVE without preceding ENTER

task reset;
input [13:0] err_code;
input [27:0] code_addr;
begin
	$display("CPU reset: errcode %h, addr %d", err_code, code_addr);
	$display("Halt.\n");
	$finish;
end
endtask

// word types
`define WT_MASK 16'hc000      // general bitmask for the word type constants
`define WT_CPU  16'h0000      // code word containing two 7-bit CPU instructions
`define WT_DNL  16'h4000      // data word, not last in a VLN
`define WT_DL   16'h8000      // data word, last in a VLN
`define WT_IGN  16'hc000      // ignored word (used by the Torth compiler to store labels)

// bitmasks
`define MASK7  'h000000000000007f
`define MASK14 'h0000000000003fff
`define OVER14 'h00ffffffffffc000
`define MASK28 'h000000000fffffff
`define OVER28 'h00fffffff0000000
`define MASK56 'h00ffffffffffffff
`define OVER56 'hff00000000000000

// CAR bitmask definitions
`define CA_LENGTH   2   // number of bits of the CA_xx condition
`define CA_MASK     3   // general bitmask
`define CA_NONE     0   // normal execution (no conditional structure)
`define CA_SKIP     1   // skipping mode
`define CA_NOEXEC   2   // conditional structure; not executing code
`define CA_EXEC     3   // conditional structure; executing code

// `define i_ 'h00
`define i_SETPR 'h01
// `define i_ 'h02
`define i_BREAK 'h03
`define i_AGAIN 'h04
`define i_CALL 'h05
`define i_ACALL 'h06
`define i_RETURN 'h07
`define i_MAXTHDS 'h08
`define i_THREADS 'h09
// `define i_ 'h0a
`define i_ENDALL 'h0b
`define i_END 'h0c
`define i_NTCALL 'h0d
`define i_NTACALL 'h0e
`define i_SYSFN 'h0f
// `define i_ 'h10
`define i_EMPTY 'h11
`define i_DEPTH 'h12
`define i_DROP 'h13
`define i_DUP 'h14
`define i_SWAP 'h15
`define i_ROT 'h16
`define i_OVER 'h17
`define i_ENTER 'h18
`define i_LEAVE 'h19
`define i_GETVAR 'h1a   // alias: !
`define i_SETVAR 'h1b   // alias: =!
`define i_DELAY 'h1c
// `define i_ 'h1d
// `define i_ 'h1e
// `define i_ 'h1f
`define i_COM 'h20
`define i_NOT 'h21
`define i_AND 'h22
`define i_OR 'h23
`define i_XOR 'h24
// `define i_ 'h25
`define i_SHL 'h26
`define i_SHR 'h27
`define i_SM 'h28       // alias: <
`define i_SMEQ 'h29     // alias: <=
`define i_EQ 'h2a       // alias: ==
`define i_NEQ 'h2b      // alias: <>
`define i_GTEQ 'h2c     // alias: >=
`define i_GT 'h2d       // alias: >
// `define i_ 'h2e
// `define i_ 'h2f
// `define i_ 'h30
// `define i_ 'h31
// `define i_ 'h32
// `define i_ 'h33
// `define i_ 'h34
// `define i_ 'h35
// `define i_ 'h36
// `define i_ 'h37
// `define i_ 'h38
// `define i_ 'h39
// `define i_ 'h3a
// `define i_ 'h3b
// `define i_ 'h3c
// `define i_ 'h3d
// `define i_ 'h3e
// `define i_ 'h3f
`define i_ADD 'h40      // alias: +
// `define i_ 'h41
`define i_SUB 'h42      // alias: -
// `define i_ 'h43
`define i_MUL 'h44      // alias: *
// `define i_ 'h45
`define i_DIV 'h46      // alias: /
`define i_MOD 'h47      // alias: //
`define i_INC 'h48      // alias: ++
`define i_DEC 'h49      // alias: --
// `define i_ 'h4a
`define i_RANDOM 'h4b
// `define i_ 'h4c
// `define i_ 'h4d
// `define i_ 'h4e
// `define i_ 'h4f
`define i_MEMFILL 'h50  // alias: FILL
// `define i_ 'h51
`define i_MEMDIFF 'h52  // alias: DIFF
`define i_MEMCOPY 'h53  // alias: =
// `define i_ 'h54
// `define i_ 'h55
// `define i_ 'h56
// `define i_ 'h57
`define i_STRLEN 'h58   // alias: LEN$
`define i_STRSCAN 'h59  // alias: SCAN$
`define i_STRDIFF 'h5a  // alias: DIFF$
`define i_STRCOPY 'h5b  // alias: =$
// `define i_ 'h5c
// `define i_ 'h5d
// `define i_ 'h5e
// `define i_ 'h5f
// `define i_ 'h60
// `define i_ 'h61
// `define i_ 'h62
// `define i_ 'h63
`define i_RD32 'h64
`define i_RD16 'h65
`define i_RD8 'h66
// `define i_ 'h67
// `define i_ 'h68
// `define i_ 'h69
// `define i_ 'h6a
// `define i_ 'h6b
`define i_WR32 'h6c
`define i_WR16 'h6d
`define i_WR8 'h6e
// `define i_ 'h6f
`define i_DO 'h70
`define i_SKIP 'h71
// `define i_ 'h72
// `define i_ 'h73
// `define i_ 'h74
// `define i_ 'h75
// `define i_ 'h76
// `define i_ 'h77
`define i_REPEAT 'h78
`define i_UNTIL 'h79
`define i_WHILE 'h7a
`define i_REPIF 'h7b
`define i_IF 'h7c
`define i_ENDIF 'h7d
`define i_ELSE 'h7e
`define i_NOP 'h7f

// non-standard instructions

`define i_PRINT_STACK 'h02

function string opcode2str (input logic [6:0] opcode);
begin
	case (opcode)
	`i_ACALL           : opcode2str = "ACALL";
	`i_ADD             : opcode2str = "ADD";
	`i_AGAIN           : opcode2str = "AGAIN";
	`i_AND             : opcode2str = "AND";
	`i_BREAK           : opcode2str = "BREAK";
	`i_CALL            : opcode2str = "CALL";
	`i_COM             : opcode2str = "COM";
	`i_DEC             : opcode2str = "DEC";
	`i_DELAY           : opcode2str = "DELAY";
	`i_DEPTH           : opcode2str = "DEPTH";
	`i_DIV             : opcode2str = "DIV";
	`i_DO              : opcode2str = "DO";
	`i_DROP            : opcode2str = "DROP";
	`i_DUP             : opcode2str = "DUP";
	`i_ELSE            : opcode2str = "ELSE";
	`i_EMPTY           : opcode2str = "EMPTY";
	`i_END             : opcode2str = "END";
	`i_ENDALL          : opcode2str = "ENDALL";
	`i_ENDIF           : opcode2str = "ENDIF";
	`i_ENTER           : opcode2str = "ENTER";
	`i_EQ              : opcode2str = "EQ";
	`i_GETVAR          : opcode2str = "GETVAR";
	`i_GT              : opcode2str = "GT";
	`i_GTEQ            : opcode2str = "GTEQ";
	`i_IF              : opcode2str = "IF";
	`i_INC             : opcode2str = "INC";
	`i_LEAVE           : opcode2str = "LEAVE";
	`i_MAXTHDS         : opcode2str = "MAXTHDS";
	`i_MEMCOPY         : opcode2str = "MEMCOPY";
	`i_MEMDIFF         : opcode2str = "MEMDIFF";
	`i_MEMFILL         : opcode2str = "MEMFILL";
	`i_MOD             : opcode2str = "MOD";
	`i_MUL             : opcode2str = "MUL";
	`i_NEQ             : opcode2str = "NEQ";
	`i_NOP             : opcode2str = "NOP";
	`i_NOT             : opcode2str = "NOT";
	`i_NTACALL         : opcode2str = "NTACALL";
	`i_NTCALL          : opcode2str = "NTCALL";
	`i_OR              : opcode2str = "OR";
	`i_OVER            : opcode2str = "OVER";
	`i_PRINT_STACK     : opcode2str = "PRINT_STACK";
	`i_RANDOM          : opcode2str = "RANDOM";
	`i_RD16            : opcode2str = "RD16";
	`i_RD32            : opcode2str = "RD32";
	`i_RD8             : opcode2str = "RD8";
	`i_REPEAT          : opcode2str = "REPEAT";
	`i_REPIF           : opcode2str = "REPIF";
	`i_RETURN          : opcode2str = "RETURN";
	`i_ROT             : opcode2str = "ROT";
	`i_SETPR           : opcode2str = "SETPR";
	`i_SETVAR          : opcode2str = "SETVAR";
	`i_SHL             : opcode2str = "SHL";
	`i_SHR             : opcode2str = "SHR";
	`i_SKIP            : opcode2str = "SKIP";
	`i_SM              : opcode2str = "SM";
	`i_SMEQ            : opcode2str = "SMEQ";
	`i_STRCOPY         : opcode2str = "STRCOPY";
	`i_STRDIFF         : opcode2str = "STRDIFF";
	`i_STRLEN          : opcode2str = "STRLEN";
	`i_STRSCAN         : opcode2str = "STRSCAN";
	`i_SUB             : opcode2str = "SUB";
	`i_SWAP            : opcode2str = "SWAP";
	`i_SYSFN           : opcode2str = "SYSFN";
	`i_THREADS         : opcode2str = "THREADS";
	`i_UNTIL           : opcode2str = "UNTIL";
	`i_WHILE           : opcode2str = "WHILE";
	`i_WR16            : opcode2str = "WR16";
	`i_WR32            : opcode2str = "WR32";
	`i_WR8             : opcode2str = "WR8";
	`i_XOR             : opcode2str = "XOR";
	default            : opcode2str = "???";
	endcase
end
endfunction


`endif
