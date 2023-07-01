	.CR	SCMP
	.TF	life_fa0.hex,INT
	.LF	life_fa0.lst
; *****************************************************************************
;
;       MK14 1 Dimensional Life by Paul M. Glover.
;	from Computing Today Page 62 and 63 - October 1979
;
;       Converted to SBASM Assembler, transcribed and further commented by
;	Tim Gilberts
;
;       Full details are given in the article on the website
;	http://www.flaxcottage.com/ComputingToday/7910.pdf
;
;	See also the discussion on versions of Conway's game of life described
;	in Issue 12 of the 1978 Byte:
;
;	https://archive.org/details/byte-magazine-1978-12/page/n69
;
;	29/5/2019:
;		First release (v0p3)
; *****************************************************************************

CELLST	.EQ	0x0B80		; As original - change to 0B80 or similar if no IO/RAM or on emulator
GENSPED .EQ	0x3F		; Faster than 0xFF original which was "5 seconds per generation"
	
	.OR	0x0F12
	
T0  .DB 0		;0F12
T1  .DB 0		;0F13
T2  .DB 0		;0F14
N   .DB 0		;0F15
Sum .DB 0		;0F16


	.OR 	0x0F20
	
Start	LDI	CELLST/256	
	XPAH	P2		;P2 = 0E80
	LDI	CELLST&255	;(or start of cells).
	XPAL	P2		;(2) *** Check best Syntax
	LDI	0x00
	ST	N
	ST	T1
	ST	T2		;clear stores
	ST	0x11(2)
	ST	0x10(2)
	
	NOP			; gaps filled with NOPs (Probably hand assembled..)
	NOP
	NOP
	NOP
	
Next	LD	@01(P2)		; @ in listing meaning use Auto Increment/Decrement index
	ST	T0		; T0 = state of cells
	CCL
	LD	T1
	ADD	T2		; Sum = no of neighbours
	ADD	@01(2)
	ADD	00(2)
	ST	Sum
	LD	T0
	JNZ	Space		; Jump if cell present
	SCL
	LD	Sum
	CAI	0x02
	JZ	Born		; If sum = 2 or 4 then jump to born.
	SCL
	CAI	0x01
	JZ	Born
	JMP	Same		; Otherwise as before
	
	NOP			; Gaps filled with NOPs
	NOP
	NOP

Space	SCL
	LD	Sum
	CAI	0x02
	JZ	Same		; If sum =2 or 4 cell remains the same
	SCL
	CAI	0x02
	JZ	Same
	
	NOP
	NOP
	NOP
	NOP
	
Dies	LDI	0x00		; Otherwise dies
	ST	-2(2)		; (Clear location) - was no X' in mag perhaps typo?
	JMP	Same
	
Born	LDI	0x01		; Cell is born
	ST	-2(2)		; (set location)
	
	NOP
	NOP
	NOP
	NOP
	
Same	LD	@-1(2)		; Decrement pointer.
	ILD	N		; Increment counter
	XRI	0x10		; and if all cells
	JZ	Display		; examined jump to
	LD	T1		; display
	ST	T2		; T2 = T1
	LD	T0
	ST	T1		; T1 = T0
	JMP	Next		; go and examine next cell.
	
	.OR 0x0F9C
	
Cycles	.DB 0
Count	.DB 0
Seg	.DB 0

	.DB 0

Display	LDI	GENSPED		; Entry Point
	ST	Cycles		; 0xFF gives 5 seconds per generation
	
Again	LDI	0x0D
	XPAH	P1		; P1 = 0D08 - *** changed to 0908 not to use shadows
	LDI	0x08
	XPAL	P1
	LDI	CELLST/256	
	XPAH	P2		; P2 = 0E80 
	LDI	CELLST&255	; (or start of cells)
	XPAL	P2
	LDI	0x10		; count = X'10
	ST	Count
	
Repeat	LDI	0xFF		; Delay
	DLY	0x01
	LDI	0x00
	ST	Seg		; Clear seg.
	LD	@01(2)
	JZ	N1		; Jump if cell vacant
	LDI	0x30		; otherwise seq = X'30
	ST	Seg
	
N1	LD	@01(2)		; Jump if next cell is
	JZ	N2		; vacant
	CCL
	LD	Seg		; Otherwise
	ADI	0x06		; Seg = Seg + X'06
	ST	Seg
	
N2	LD	Seg
	ST	@-1(1)		; Store Seg to display
	DLD	Count		; Decrement count
	JNZ	Repeat		; and repeat if not
	DLD	Cycles		; zero.
	JNZ	Again		; repeat if not zero.

	LDI	0x1F		; Cause jump to
	XPAL	P0		; 0F20

	.OR CELLST	
#	.OR 0x0880		; Sample pattern - just a few iterations and then stagnates but does not die 01101 <> 10110

	.DB 1
	.DB 1
	.DB 0
	.DB 0
	.DB 0
	.DB 1
	.DB 1
	.DB 0
	.DB 0
	.DB 0
	.DB 1
	.DB 1
	.DB 0
	.DB 1
	.DB 0
	.DB 1

;Support SH PI-Progammer Auto Start

;	.OR 0xFFFE
;	.DB 0x0F
;	.DB 0xA0

;	.EN

