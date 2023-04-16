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
	$display("CPU reset: errcode %h, addr %h", err_code, code_addr);
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


`define i_NOP 'h7f
`define i_SKIP 0
`define i_DO 0
`define i_RETURN 0
`define i_CALL 0
`define i_ACALL 0
`define i_NTCALL 0
`define i_NTACALL 0
`define i_END 0
`define i_ENDALL 0
`define i_MAXTHDS 0
`define i_THREADS 0
`define i_DUP 'h14
`define i_DROP 0
`define i_SWAP 0
`define i_ROT 0
`define i_OVER 0
`define i_DEPTH 'h12
`define i_EMPTY 'h11
`define i_AND 0
`define i_OR 0
`define i_XOR 0
`define i_COM 0
`define i_NOT 0
`define i_SHL 0
`define i_SHR 0
`define i_ADD 0
`define i_SUB 0
`define i_MUL 0
`define i_DIV 0
`define i_MOD 0
`define i_EQ 0
`define i_NEQ 0
`define i_GT 0
`define i_GTEQ 0
`define i_SM 0
`define i_SMEQ 0
`define i_INC 0
`define i_DEC 0
`define i_IF 0
`define i_ELSE 0
`define i_ENDIF 0
`define i_REPEAT 0
`define i_REPIF 0
`define i_UNTIL 0
`define i_WHILE 0
`define i_AGAIN 0
`define i_BREAK 0
`define i_RD8 0
`define i_RD16 0
`define i_RD32 0
`define i_RDVLN 0
`define i_WR8 0
`define i_WR16 0
`define i_WR32 0
`define i_WRVLN 0
`define i_RANDOM 0
`define i_MEMCOPY 0
`define i_STRCOPY 0
`define i_MEMDIFF 0
`define i_STRDIFF 0
`define i_MEMFILL 0
`define i_STRLEN 0
`define i_STRSCAN 0
`define i_SYSFN 0
`define i_DELAY 0
`define i_ENTER 0
`define i_LEAVE 0
`define i_SETPR 0
`define i_GETVAR 0
`define i_SETVAR 0

// non-standard instructions

`define custom_PRINT_STACK 'h02

`endif
