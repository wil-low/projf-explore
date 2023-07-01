	.CR	SCMP
	.TF	FALLMAN.hex,INT
	.LF	FALLMAN.lst
; *****************************************************************************
; Falling Man demo from Practical Electronics Dec 1979 by Nick Toop designer of
; the SoC VDU.
;
; Typed in for SBASM by T.Gilberts May 2020
;
; *****************************************************************************

RAM	.EQ	0x0F00		;For Variables
DISP	.EQ	0x0B00		;Display Memory
;
;RAM OFFSETS
;
COL	.EQ	2		;Column
CNT	.EQ	3		;Counter
ROW	.EQ	4		;Row count
;
	.OR	0x0F20

ENTER:	
;	LDI	3		;Enable VDU and Graphics mode (F1-ON,F2-ON=Graphics)
;	CAS
;	JMP	ENTER
;not needed at mo as sendv14 does a reset at the end before the execute?	
	

START:	LDI	RAM/256
	XPAH	P3
	LDI	RAM&255
	XPAL	P3		;P3 to variables

	LDI	DISP/256	;BEGIN: Label never used
	XPAH	P1
	
	LDI	#6		;LOOP: Label never used
	ST	COL(P3)
	
NEWMAN:	XPAL	P1		;Begin new man
	LDI	MAN/256
	XPAH	P2
	LDI	MAN&255
	XPAL	P2
	LDI	#19		;Hex 0x13 should be generated
	ST	CNT(P3)

COPY:	LDI	15		;Rows per picture
	ST	ROW(P3)
	
NEWROW:	LD	@1(P2)		;Get byte1 and increment
	ST	@1(P1)
	LD	@1(P2)
	ST	@7(P1)		;Point to next row
	DLD	ROW(P3)		;Picture done?
	JNZ	NEWROW
	LD	@-30(P2)	;Reset P2
	LD	@-112(P1)	;Reset P1 1 Row down
	DLY	0x40
	DLD	CNT(P3)
	XRI	4		;4 sweeps to go?
	JZ	LAND		;YES = Change Picture
	XRI	4		;Restore CNT
	JNZ	COPY		;Fresh sweep?
	DLY	0xFF		;Leave man standing
	DLD	COL(P3)		;Next man
	DLD	COL(P3)		;Subtract 2
	JP	NEWMAN		;All done? I.e. if positive

	LDI	#0

CLEAR:	XPAL	P1		;Clear Screen
	LDI	0		;Blank
	ST	@1(P1)
	XPAL	P1
	JNZ	CLEAR		;More to do
	JMP	START		;Repeat for ever.
	
LAND:	LD	@+28(P2)	;P2 to standing man
	JMP	COPY

;	BIT-PATTERNS FOR FALLING MAN
MAN:	.DB	0x00,0x00,0x43,0x08,0x43,0x08
	.DB	0x3F,0xF0,0x0F,0xC0,0x07,0x80
	.DB	0x03,0x00,0x07,0x80,0x04,0x80
	.DB	0x08,0x40,0x08,0x40,0x04,0x80
	.DB	0x04,0x80,0x04,0x80,0x00,0x00

;	BIT-PATTERNS FOR STANDING MAN
	.DB	0x03,0x00,0x03,0x00,0x0F,0xC0
	.DB	0x1F,0xE0,0x27,0x90,0x43,0x08
	.DB	0x07,0x80,0x0C,0xC0,0x10,0x20
	.DB	0x20,0x10,0x10,0x20,0x08,0x40
	.DB	0x00,0x00,0x00,0x00,0x00,0x00

	
; As we do not have to type it in... line em up to fall..

	.DB	0x03,0x00,0x03,0x00,0x0F,0xC0
	.DB	0x1F,0xE0,0x27,0x90,0x43,0x08
	.DB	0x07,0x80,0x0C,0xC0,0x10,0x20
	.DB	0x20,0x10,0x10,0x20,0x08,0x40
	.DB	0x00,0x00,0x00,0x00,0x00,0x00
	
	.DB	0xFF,0xFF	
	.DB	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
		
;Support SH PI-Progammer Auto Start

	.OR 0xFFFE
	.DB ENTER/256
	.DB ENTER&255
	
	.EN
