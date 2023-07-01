	.CR	SCMP
	.TF	MINEFLD.hex,INT
	.LF	MINEFLD.lst
; *****************************************************************************
; MK14 MINEFIELD
;
; V.W. Morley of Staffordshire
;
; From Microbus - Practical Electronics June 1980
; Originally designed for the PE VDU
;
; Typed in from HEX listing disassembled and added a CLS
; and converted for SoC VDU by T.J.Gilberts May 2019
;
; Version 0p3
;
 
VDU	.EQ	0x0200		; Section to CLS on VDU

 
 	.ORG	0x0F1F		; Was 0x0F1F
 	
Var	.DB	0

Entry:
	XPPC	P3

Start:				;Initial address
	LDI	#0x30		;48
	ST	Var-$(0) 	;This is 0x0F19 - a variable?

	LDI	/VDU		;Set Pointer 2 to 0420 (some way into the PE VDU RAM?
	XPAH	P2
	LDI	#0x20
	XPAL	P2
	 
PossLoop1:
	LDI	#0x00
		
	ST	@0x15(P2)	;C8 is ST E 1110 so m=1 ptr=10 means auto indexed 2
				;as 0x15 is +Ve the effective address is 0(2) then add 0x15 to 2

	DLD	Var-$(P0)	;Decrement and load (relative to PC) does 48 down to 0
 	
;	JZ	SkipJump
	JNZ	PossLoop1	;Was JMP 0xF6 is -10?
	
;SkipJump:
	XPPC	P3		; Return to ScIOS - Waits for Go to launch a tank
	
	LDI	/VDU
	XPAH	P2
	LDI	#0x01
	XPAL	P2 	

	LDI	#0x1B		;[0]
	ST	-1(P2)		;and after score
	LDI	#0x30		;Set TANK number to 0
	ST	0(P2)		;C8 is ST A 1010 so m=0 ptr=10 means indexed 2
	LDI	#0x1D
	ST	1(P2)

Back76:
	LDI	/VDU
	XPAH	P2
	LDI	#0x06
	XPAL	P2

	LDI	/VDU
	XPAH	P1
 	LDI	#0x09
	XPAL	P1

Back86or102:	
	LDI	#0x58
	ST	@2(P2)
	ST	@1(P2)

SPEEDA:
	DLY	0x7F		;Was 0x66 make a variable...
 	
	LDI	#0x20
	ST	@-3(P2)
	ST	@1(P2)
SPEEDB:
	DLY	0x7F		;Was 0x66 make a variable...

	LD	@1(P1)		;This is finding if we have hit something perhaps?

	JZ	SkipJump0

;Need to check if we have run off screen
	XPAH	P1		;If the High byte is now 
	XRI	/VDU+0x0100	;0x100 extra above address - HARD CODED DO BETTER
	JZ	ENTER		;Restart for now - FASTER
	LDI	/VDU		;Restore Pointer
	XPAH	P1
	
	JMP	Jump50 

SkipJump0:	
	LDI	#0x20
	ST	@1(P2)
	ST	@1(P2)
	ST	@1(P2)

	LDI	#0x02		;B
	ST 	@1(P1)
	LDI	#0x01		;A
	ST	@1(P1)
	LDI	#0x0E		;N
	ST	@1(P1)
	LDI	#0x00		;G originally now lay a new mine
	ST	@1(P1)

	LDI	/VDU
	XPAH	P3
	LDI	#0x01
	XPAL	P3
 
;This is the score update I think?
	LD	0(P3)
	DAI 	#1		;Decimal add immediate
	ST	0(P3)

	XRI	#0x40		;All 10 tanks used?
	 	
;	JZ	SkipJump2
	JNZ	Back76		;Was JMP

SkipJump2:	
	LDI	#0x00		;Is this an attempt to return to SCIOS?
	XPAH	P3
	LDI	#0x22	
	XPAL	P3
	LDI	#Entry&255
	XPAL	P0		;Abs Jump in Page as next is out of range
;	JMP	Entry		;In SCIOS 2 this is XPPC 

Jump50:
	LDI	#0x0D		;Keyboard ROW scan
	XPAH	P3
	LDI	#0x00
	XPAL	P3

	LD	7(P3)

	XRI	#0xEF

;	JZ	SkipJump3
	JNZ	Back86or102		;Back 86 was JMP

;SkipJump3: 	
	LDI	#0x20			;Attempt to disarm....
 	ST	@-3(P2)
	ST	@1(P2)
	ST	@4(P2)

	ST	@-3(P1)
	ST	@1(P1)
	ST	@4(P1)

 	JMP	Back86or102

;Support Auto config of INS8154 controlled VDU
ENTER:				;As we are using 8154 we need to set Character mode
	LDI	0x08
	XPAH	P2
	LDI	0x00
	XPAL	P2
	LDI	0xFD
	ST	0x22(P2)	;Turn on ALL 8 Port A as Outputs
	LDI	0xBE		;Enable in text mode with F00 and B00 visible
	ST	0x20(P2)
	
	LDI	0x00		;or lower FLAG2 for other card designs to enable
	CAS	
	
	LD	SPEEDA-$(P0)	;Set speed faster each time
	SCL
	CAI	#0x05
;Should check if still +ve etc as they have beaten us!
	ST	SPEEDA-$(P0)	
	ST	SPEEDB-$(P0)
		
;	JNZ	CLEAR	
;We need to reward the user for beating 7 levels...

; CLS from Practical Electronics Aug 1981

CLEAR:	LDI 	/VDU
	XPAH	P2
	LDI	#0x00
LOOP:	XPAL	P2
	LDI	0x20		;Space
	ST	@1(P2)
	XPAL	P2
	JNZ	LOOP

	JMP	SkipJump2

;Use up spare space with Title and "Instructions"

	.DB	0x4D,0x49,0x4E,0x45,0x46,0x49,0x45,0x4C,0x44,0x6A
	.DB	0x14,0x01,0x0E,0x0B,0x13,0x3A,0x07,0x0F,0x2F,0x06,0x20	


; Add code to hex for SH PI-Programmer to auto execute after load...

	.ORG	0xFFFE
	.DB 	ENTER/256
	.DB 	ENTER&255
    
    
; Execute at 0F21 with a clear screen a minefield will be displayed. Pressing
; GO a second time sets in motion a tank, represented by 'X' moving to the
; mines.  To jump and difuse a mine press the 'F' key at the right moment.
; BANG will appear if this fails and a new tank starts from the beginning.
; The number of tanks used 1-10 will be displayed - after 10 the program stops.
; Pressing GO twice then reloads the minefield and starts the game again, with
; the last BANG still displayed as the target to beat.

	.EN
