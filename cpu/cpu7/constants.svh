// word types
`define WT_MASK 16'hc000      // general bitmask for the word type constants
`define WT_CPU  16'h0000      // code word containing two 7-bit CPU instructions
`define WT_DNL  16'h4000      // data word, not last in a VLN
`define WT_DL   16'h8000      // data word, last in a VLN
`define WT_IGN  16'hc000      // ignored word (used by the Torth compiler to store labels)

// bitmasks
`define MASK7  56'h000000000000007f
`define MASK14 56'h0000000000003fff
`define OVER14 56'h00ffffffffffc000
`define MASK28 56'h000000000fffffff
`define OVER28 56'h00fffffff0000000
`define MASK56 56'h00ffffffffffffff
`define OVER56 56'hff00000000000000

// CAR bitmask definitions
`define CA_LENGTH   2   // number of bits of the CA_xx condition
`define CA_MASK     3   // general bitmask
`define CA_NONE     0   // normal execution (no conditional structure)
`define CA_SKIP     1   // skipping mode
`define CA_NOEXEC   2   // conditional structure; not executing code
`define CA_EXEC     3   // conditional structure; executing code
