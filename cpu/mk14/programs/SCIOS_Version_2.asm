;
; Mk14 Firmware Version 2
;
; Formatted for the SB-Assembler (https://www.sbprojects.net/sbasm/)
;
; Chris Oddy Dec 2020
;
		.CR		scmp
		.LF		SCIOS_Version_2.lst		; listing file
		.TF		SCIOS_Version_2.bin		; object file
;
RAM		.EQ		$0F00
DISPLY	.EQ		$0D00
;
;		RAM Offsets
;
DL		.EQ		0			; Segment for digit 1
DH		.EQ		1			; Segment for digit 2
D3 		.EQ		2			; Segment for digit 3
D4 		.EQ		3			; Segment for digit 4
ADLL 	.EQ		4			; Segment for digit 5
ADLH 	.EQ		5			; Segment for digit 6
ADHL 	.EQ		6			; Segment for digit 7
ADHH 	.EQ		7			; Segment for digit 8
D9 		.EQ		8			; Segment for digit 9
CNT 	.EQ		9			; Counter
PUSHED 	.EQ		10			; Key Pushed
CHAR 	.EQ		11			; Char Read
ADL 	.EQ		12			; Memory Address Low
WORD 	.EQ		13			; Memory Word
ADH 	.EQ		14			; Memory High
DDTA 	.EQ		15			; First Flag
ROW 	.EQ		16			; Row Counter
NEXT 	.EQ		17			; Flag for now data
;
;		RAM Pointers used by SCIOS, P3 is saved elsewhere
;
P1H 	.EQ		$0FF9
P1L 	.EQ		$0FFA
P2H 	.EQ		$0FFB
P2L 	.EQ		$0FFC
A 		.EQ		$0FFD
EE 		.EQ		$0FFE		('E' is a reserved word)
S 		.EQ		$0FFF
;
;		Monitor Operation Summary
;
;		Initially in 'Address Entry' Mode
;
;	TERM:
;		Change to 'Data Entry' Mode
;
; 	MEM:
;		Increment Memory Address
;
; 	GO:
;		The registers are loaded from RAM and program
;		is transferred using XPPC P3.
;		To get back do XPPC P3.
;
		.OR		$0000		; set origin
;
;		Monitor Listing
;
		HALT				; zeros displayed on reset
		ST		@-1(3)		; SO P3=-1
;
		JMP START
;
;		Debug Exit
;		Restore Environment
;
GOOUT:	XPAH	3
		LD		ADL(2)
		XPAL	3
		LD		@-1(3)		; fix go address
		LD		EE
		XAE					; restore registers
		LD		P1L
		XPAL	1
		LD		P1H
		XPAH	1
		LD		P2L
		XPAL	2
		LD		P2H
		XPAH	2
		LD		S
		HALT				; reset single step
		CAS
		LD		A
		NOP
		IEN
		XPPC	3
;		Entry Point for Debug
START:	ST		A
		LDE
		ST		EE
		CSA
		ST		S
		XPAH	1
		ST		P1H
		XPAL	1
		ST		P1L
		LDI		/RAM		; point P2 to RAM
		XPAH	2
		ST		P2H
		LDI		#RAM
		XPAL	2
		ST		P2L
		LD		@1(3)		; bump P3 for return
		XPAL	3			; save P3
		ST		ADL(2)
		XPAH	3
		ST		ADH(2)
		LDI		0
		ST		D3(2)
		ST		D4(2)
		LDI		1
		XPAH	3
ABORT:	JMP		MEM
GONOW:	LD		ADH(2)
		JMP		GOOUT
;
;		Tape Interface Routines
;
COUNT	.EQ		-43	($D5)
LEN		.EQ		-42	($D6)
;
;		Store To Tape = $0052
;
TOTAPE:	LD		@1(1)
		XAE
		LDI		1
NXT:	ST		COUNT(3)
		LDI		1
		CAS
		DLY		8
		LD		COUNT(3)
		ANE
		JZ		ZERO
		DLY		$018
		LDI		0
		CAS
		JMP		DONE
ZERO:	LDI		0
		CAS
		DLY		$018
DONE:	DLY		$020
		LD		COUNT(3)
		ADD		COUNT(3)
		JNZ		NEXT
		DLD		LEN(3)
		JNZ		TOTAPE
		XPPC	3
;
;		Load From Tape = 0007C
;
FRTAPE:	LDI		8
		ST		COUNT(3)
LOOP:	CSA
		ANI		$20
		JZ		LOOP
		DLY		$01C
		SIO
		DLY		$01C
		DLD		COUNT(3)
		JNZ		LOOP
		LDE
		ST		@1(1)
		JMP		FRTAPE
;
;		Offset Calculation = 0093
;
OFFSET:	LD		@-2(2)		; subtract 2 from destination address
		XPAL	2			; put low byte in AC
		SCL					; set carry for subtraction
		CAD		-40(3)		; subtract low byte of jump instruction address ($D8)
		ST		+1(1)		; Put in jump operand
		XPPC	3			; return to monitor
		NOP
DTACK:	ILD		ADH(2)
		JMP		DATA
MEMDN:	LD		ADH(2)		; put word in memory
		XPAH	1
		LD		ADL(2)
		XPAL	1
		LD		WORD(2)
		ST		(1)
		JMP		DATACK
MEMCK:	XRI		$06			; check for GO
		JZ		GONOW
		XRI		$05			; check for TERM
		JZ		DATA		; check if done
		ILD		ADL(2)		; update address low
		JNZ		DATA
		JMP		DTACK
;		Mem Key Pushed
MEM:	LDI		-1
		ST		NEXT(2)		; set first flag
		ST		DDTA(2)		; set flag for address now
MEML:	LD		ADH(2)
		XPAH	1			; set P1 for memory address
		LD		ADL(2)
		XPAL	1
		LD		(1)
		ST		WORD(2)		; save memory data
		LDI		#DISPD-1	; fix data segment
		XPAL	3
		XPPC	3			; go to DISPD set segment for data
		JMP		MEMCK		; command return
		LDI		#ADR-1		; make address
		XPAL	3
		XPPC	3
		JMP		MEML		; get next character
DATA:	LDI		-1			; set first flag
		ST		DDTA(2)
		LD		ADH(2)		; set P1 to memory address
		XPAH	1
		LD		ADL(2)
		XPAL	1
DATACK:	LD		(1)			; read data word
		ST		WORD(2)		; save for display
DATAL:	LDI		#DISPD-1	; fix data segment
		XPAL	3
		XPPC	3			; fix data segment-GO to DISPD
		JMP		MEMCK		; character return
		LDI		4			; set counter for number of shifts
		ST		CNT(2)
		ILD		DDTA(2)		; check if first
		JNZ		DNFST
		LDI		0			; zero word if first
		ST		WORD(2)
		ST		NEXT(2)		; set flag for address done
DNFST:	CCL
		LD		WORD(2)		; shift left
		ADD		WORD(2)
		ST		WORD(2)
		DLD		CNT(2)		; check for 4 shifts
		JNZ		DNFST
		LD		WORD(2)		; add new data
		ORE
		ST		WORD(2)
		JMP		MEMDN
;		Segment Assignments
SA		.EQ		1
SB		.EQ		2
SC		.EQ		4
SD		.EQ		8
SE		.EQ		16
SF		.EQ		32
SG		.EQ		64
;		'Hex Number to Seven Segment Table'
CROM:	.DB		SA+SB+SC+SD+SE+SF
		.DB		SB+SC
		.DB		SA+SB+SD+SE+SG
		.DB		SA+SB+SC+SD+SG
		.DB		SB+SC+SF+SG
		.DB		SA+SC+SD+SF+SG
		.DB		SA+SC+SD+SE+SF+SG
		.DB		SA+SB+SC
		.DB		SA+SB+SC+SD+SE+SF+SG
		.DB		SA+SB+SC+SF+SG
		.DB		SA+SB+SC+SE+SF+SG
		.DB		SC+SD+SE+SF+SG
		.DB		SA+SD+SE+SF
		.DB		SB+SC+SD+SE+SG
		.DB		SA+SD+SE+SF+SG
		.DB		SA+SE+SF+SG
;		'Make 4 Digit Address'
;		Shift address left one digit then add new low hex
;		digit, hex digit in E register, P2 points to RAM
ADR:	LDI		4			; set number of shifts
		ST		CNT(2)
		ILD		DDTA(2)		; check if first)
		JNZ		NOTFST		; jump if no
		LDI		0			; zero address
		ST		ADH(2)
		ST		ADL(2)
NOTFST:	CCL					; clear link
		LD		ADL(2)		; shift address left 4 times
		ADD		ADL(2)
		ST		ADL(2)		; save it
		LD		ADH(2)		; now shift high
		ADD		ADH(2)
		ST		ADH(2)
		DLD		CNT(2)		; check if shifted 4 times
		JNZ		NOTFST		; jump if not done
		LD		ADL(2)		; now add new number
		ORE
		ST		ADL(2)		; number is now updated
		XPPC	3
;		'Data to Segments'
;		Convert hex data to segments, P2 points to RAM, drops through to hex conversion
DISPD:	LDI		/CROM		; set address of table
		XPAH	1
		LDI		#CROM
		XPAL	1
		LD		WORD(2)		; get memory word
		ANI		$0F
		XAE
		LD		-128(1)		; get segment display
		ST		DL(2)		; save at data low
		LD		WORD(2)		; fix high
		SR					; shift high to low
		SR
		SR
		SR
		XAE
		LD		-128(1)		; get segments
		ST		DH(2)		; save in data high
;		'Address to Segments'
;		P2 points to RAM, drops through to keyboard and display
DISPA:	SCL
		LDI		/CROM		; set address of table
		XPAH	1
		LDI		#CROM
		XPAL	1
LOOPD:	LD		ADL(2)		; get address
		ANI		$0F
		XAE
		LD		-128(1)		; get segments
		ST		ADLL(2)		; save segment of ADR LL
		LD		ADL(2)
		SR					; shift high digit to low
		SR
		SR
		SR
		XAE
		LD		-128(1)		; get segments
		ST		ADLH(2)
		CSA					; check if done
		ANI		$080
		JZ		DONEB
		CCL					; clear flag
		LDI		0
		ST		D4(2)		; zero digit 4
		LD		@2(2)		; fix P2 for next loop
		JMP		LOOPD
DONEB:	LD		@-2(2)		; fix P2
;		'Display and Keyboard Input'
;		Call	XPPC 3
;		Jump command in A GO=6, MEM=7,TERM=3
;		in E GO=22, MEM=23, TERM=27
;		Number return hex number in E register
;		Abort key goes to abort
;		All registers are used
;		P2 must point to RAM, address must be XXX0
;		To re-execute routine do XPPC3
KYBD:	LDI		0			; zero character
		ST		CHAR(2)
		LDI		/DISPLY		; set display address
		XPAH	1
OFF:	LDI		-1			; set row/digit address
		ST		ROW(2)		; save row counter
		LDI		10			; set row counter
		ST		CNT(2)
		LDI		0
		ST		PUSHED(2)	; zero keyboard input
		XPAL	1			; set display address low
LOOPB:	ILD		ROW(2)		; update row address
		XAE
		LD		-128(2)		; get segment
		ST		-128(1)		; send it
		DLY		0			; delay for display
		LD		-128(1)		; get keyboard input
		XRI		$FF			; check if pushed
		JNZ		KEY			; jump if pushed
BACK:	DLD		CNT(2)		; check if done
		JNZ		LOOPB		; no if jump
		LD		PUSHED(2)	; check if key
		JZ		CKMORE
		LD		CHAR(2)		; was there a character ?
		JNZ		OFF			; yes wait for release
		LD		PUSHED(2)	; no set character
		ST		CHAR(2)
		JMP		OFF
CKMORE:	LD		CHAR(2)
		JZ		OFF
;		Command Key Processing
COMAND:	XAE					; save character
		LDE					; get character
		ANI		$020		; check for command
		JNZ		CMND		; jump if command
		LDI		$080		; find number
		ANE
		JNZ		LT7			; 0 to 7
		LDI		$040
		ANE
		JNZ		N89			; 8 or 9
		LDI		$0F
		ANE
		ADI		$7			; make offset to table
		XAE					; put offset away
		LD		-128(0)		; get number
KEYRTN:	XAE					; save in E
		LD		@2(3)		; fix return
		XPPC	3			; return
		JMP		KYBD		; allows XPPC P3 to return
		.DB		$0A,$0B,$0C,$0D,$0,$0,$0E,$0F
LT7:	XRE					; keep low digit
		JMP		KEYRTN
N89:	XRE					; get low
		ADI		$08			; make digit 8 or 9
		JMP		KEYRTN
CMND:	XRE
		XRI		$04			; check if abort
		JZ		ABRT		; abort
		XPPC	3			; in E 23=MEM,  22=GO, 27=TERM
							; in A 7=MEM, 6=GO, 3=TERM
		JMP		KYBD		; allows just a XPPC P3 to return
KEY:	ORE					; make character
		ST		PUSHED(2)	; save character
		JMP		BACK
ABRT:	LDI		\ABORT
		XPAH	3
		LDI		#ABORT-1
		XPAL	3
		XPPC	3			; go to abort
		.END