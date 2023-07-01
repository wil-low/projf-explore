	.cr SCMP
	.tf LIFE14_V2.hex,INT
;	.tf LIFE14_V2.BIN,BIN
	.LF LIFE14_V2.lst

;------------------------------------------------------------------------------
; LIFE14 V2 16th Apr 2023
;
; LIFE14_V2 is an adaptation of Phil_G's March 2023 version (running under KitbugPlus on the PICLv2)
; of John Conway's original Game of Life program 
; Modified by Ian Reynolds (Realtime) April 2023 for the MK14 fitted with 
; a VDU module and SRAM at 0x200-0x7FF, 0xB00-0xBFF and 0xF00-0xFFF 
; It uses a 16x30 grid to fit with the 1.5K expansion RAM
; 
; Execute from addres 0xB02
; Press 'GO' key to fill the Life cell matrix with random cells and then restart
; Press the '1' key to change the dot character to a space
; Press the 'D' key for demo mode - runs to 99 cycles and then restarts the game
; Keys are scanned every cycle, so about every 1/2 second
;
; Differences from V1
;	Demo mode added
;	Background character selection remembered when new game starts
;	Random pattern is less dense
;------------------------------------------------------------------------------

; Constants
CHARS_ROW	.EQ 16		; Characters per Row (MK14 Display limited to 16)
NUM_ROWS	.EQ 30		; Number of Rows (MK14 display limited to 32, but memory only allow for 24)
VDU			.EQ 0x200	; start of MK14 VDU memory
PROG		.EQ 0xB00	; Program start
P1			=	1
P2			=	2
P3			=	3
;
; AUT0-INDEX, WITH NEG DISPLACEMENT POINTER DECREMENTS BEFORE LOAD
; AUT0-INDEX, WITH POS DISPLACEMENT POINTER INCREMENTS AFTER LOAD
;
; Start up splash screen for LIFE14
; This table can be commented out if you want to reduce load time 
	.OR 0x200
	.DB	42,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	42,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	42,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	42,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	42,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	42,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	42,42,42,42,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,42,42,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,42,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,42,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,42,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,42,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,42,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,42,42,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,42,42,42,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,42,42,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,42,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,42,42,42,42,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,42,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,42,32,32,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,42,42,42,32,32,32,32,32,32
	.DB	32,32,32,32,32,32,32,42,32,32,32,32,13,11,49,52
	.DB	32,32,32,32,32,32,32,42,32,32,32,32,32,32,32,32	
	.DB	32,32,32,32,32,32,32,42,42,42,42,32,32,32,22,50
	
	; Do not delete this block
	.OR 0x3F0
	.DB	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	
	.OR 0x400
MARGIN:	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; SET UP INITIAL PATTERN BY EDITING BUT KEEP TO CHARS_ROW X NUM_ROWS GRID:
; Array is 16x30 = 480 bytes
GEN1:	
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0
	.DB	0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0
	.DB	0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0
	.DB	0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0
	.DB	0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

MRGIN2:	.DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;
GEN2:	.BS	480,0 ; This line can be replaced with GEN2: .BS 1,0 to decrease the load time

	.OR PROG
P3_H	.DB 0x42			; Temp Store for P3 High - filled with 42, the meaining of life
P3_L	.DB 0x42			; Temp Store for P3 low

;------------------------------------------------------------------------------
; Main programe loop
;------------------------------------------------------------------------------

; FIRST PRINT GEN1 WHILST CLEARING GEN2

ENTRY:
; Initialise E to be the background cell character
	LDI 0x2E			; = '.'
	XAE					; Use E as a variable
RE_ENTER:
CLS: 
	LDI	VDU/256+1
	XPAH P1
	LDI	0xF0  
    XPAL P1				; P1 now points to the 2nd to the last line of the display
	JS P3,CLS1			; jump subroutine to clear screen
START:
	LDI VDU/256
	ST P3_H
	LDI VDU\256
	ST P3_L
	LDI	/COUNT1
	XPAH	P3		; P3 --> COUNTERS
	LDI	#COUNT1
	XPAL	P3
	LDI	#GEN2
	XPAL	P2
	LDI	/GEN2
	XPAH	P2		; P2 --> GEN2
	LDI	#GEN1
	XPAL	P1
	LDI	/GEN1
	XPAH	P1		; P1 --> GEN1
	LDI	CHARS_ROW	; 16 CHARACTERS PER ROW
	ST	0(3)		; COUNT1
	LDI	NUM_ROWS	; 30 ROWS per Frame
	ST	1(3)		; COUNT2
NXTBYT:
	LD P3_H			; Get VDU pointer
	XPAH P3
	ST P3_H			; and swap with P3 variables pointer
	LD P3_L
	XPAL P3
	ST P3_L
	LD	@1(P1)
	JZ	DOT
	LDI	'#'
	JMP	HASH
DOT:
	LDE				; Get the background cell value from E
	ANI 0x3F		; Bit 7 is used to indicate demo mode so mask that off
HASH:
	ST @1(P3)		; Display on screen
	LDI	0
	ST	@1(P2)		; CLEAR GEN2 ARRAY

	LD P3_H			; Get Variables pointer
	XPAH P3
	ST P3_H			; and swap back with P3 VDU pointer 
	LD P3_L
	XPAL P3
	ST P3_L
	
	DLD	0(3)		; COUNT1
	JNZ	NXTBYT

	LDI	CHARS_ROW	; 16 CHARACTERS PER ROW
	ST	0(3)		; COUNT1
	DLD	1(3)		; COUNT2, Decrement number of Rows and repeat if not zero
	JNZ	NXTBYT
;
; COUNT GEN1 NEIGHBOURHOOD OCCUPANCY, RESULTS IN GEN2
;
COUNT:	LDI	#GEN1
	XPAL	P1
	LDI	/GEN1
	XPAH	P1		; P1 --> GEN1
	LDI	#GEN2
	XPAL	P2
	LDI	/GEN2
	XPAH	P2		; P2 --> GEN2
	LDI	CHARS_ROW	; 16 CHARACTERS PER ROW
	ST	0(3)		; COUNT1
	LDI	NUM_ROWS	; 30 rows per frame
	ST	1(3)		; COUNT2

NXTCNT:	CCL
	LD	-CHARS_ROW+1(P1)		; SUM OCCUPANCY OF ALL 9 NEIGHBOURHOODS
	ADD	-CHARS_ROW(P1)
	ADD	-CHARS_ROW-1(P1)
	ADD	-1(P1)
	ADD	0(P1)		; THE CURRENT CELL
	ADD	1(P1)
	ADD	CHARS_ROW-1(P1)
	ADD	CHARS_ROW(P1)
	ADD	CHARS_ROW+1(P1)
	ST	2(3)		; SAVE SUM OF 9 SQUARE OCCUPANCY
	XRI	3			; 3 MEANS LIVE
	JNZ	NXT2		; TRY 4
	LDI	1
	ST	0(P2)
	JMP	SKIP

NXT2:	LD	2(3)		; GET SUM OF 9SQUARE OCCUPANCY
	XRI	4				; 4 MEANS NO CHANGE
	JNZ	DIE
	LD	0(P1)			; CELL UNCHANGED IF SUM=4
	ST	0(P2)
	JMP	SKIP

; NOT 3 OR 4 SO DEATH!
DIE:	LDI	0
	ST	0(P2)

SKIP:	LD	@1(P1)		; INC GEN1 PTR
	LD	@1(P2)			; INC GEN2 PTR
	DLD	0(3)			; COUNT1
	JNZ	NXTCNT
	LDI	CHARS_ROW		; 16 CHARACTERS PER ROW
	ST	0(3)			; COUNT1
	DLD	1(3)			; COUNT2
	JNZ	NXTCNT

	LDI	$1B
	.DB	$20
	LDI	$5B
	.DB	$20
	LDI	$48
	.DB	$20

; COPY NEW GEN2 TO GEN1 READY FOR PRINTING

COPY:	LDI	#GEN1
	XPAL	P1
	LDI	/GEN1
	XPAH	P1		; P1 --> GEN1
	LDI	#GEN2
	XPAL	P2
	LDI	/GEN2
	XPAH	P2		; P2 --> GEN2

	LDI	CHARS_ROW	; 16 CHARACTERS PER ROW
	ST	0(3)		; COUNT1
	LDI	NUM_ROWS	; 30 rows
	ST	1(3)		; COUNT2

NXTCPY:	LD	@1(P2)	; GET GEN1 CELL
	ST	@1(P1)		; COPY TO GEN2
	DLD	0(3)		; COUNT1
	JNZ	NXTCPY
	LDI	CHARS_ROW	; 16 CHARACTERS PER ROW
	ST	0(3)		; COUNT1
	DLD	1(3)		; COUNT2
	JNZ	NXTCPY

	JS P3,LCYCLE	; Increment the on screen counter and test keyboard


JS_START:	
	JS P3,START		; Long jump to START (P3 gets re-initialised there)
	
COUNT1:	.DB	0		; PTR 3 OFFSET 0
COUNT2: .DB	0		; PTR 3 OFFSET 1
NCOUNT:	.DB	0		; PTR 3 OFFSET 2


;------------------------------------------------------------------------------
; Clear Screen subroutine
; also resets life cycle counter
; and sets the default value of E, for the background character
;------------------------------------------------------------------------------
	.OR 0xF00			; Note: this overwrites the SCIOS system variables
CLS1:					; Clear lines 30-0. It leaves the lifecycle line intact
    LDI 0x20
	ST	@-1(P1)			; Clear graphics location
	XPAH P1
	XRI	VDU/256-1		; XOR to determine if page clear completed
	JZ	CLS2			; If zero then then finished clear screen 
	XRI	VDU/256-1		; Restore P1_H
	XPAH P1
	JMP	CLS1	
CLS2:
; Reset lifecycle counter
	LDI 0x00
	ST LCYCLE_H
	ST LCYCLE_L
	RET P3

;------------------------------------------------------------------------------
; Implement a 4 digit lifecycle counter and display at bottom of the screen
; If in Demo mode (E bit 7 is set) then restart when the lifecycle counter reaches 100
; Also scan for a key press
;------------------------------------------------------------------------------

LCYCLE_H	.DB 0
LCYCLE_L	.DB 0
; Increment Life Cycle Counter
LCYCLE:
	LD LCYCLE_L   		; Increment cycle counter
	CCL
    DAI	0x01			; Decimal add - i.e. BCD counter  
	ST LCYCLE_L
	JNZ LC_DISP
	LD LCYCLE_H
	CCL
	DAI 0x01
	ST LCYCLE_H
	JNZ LC_DISP
LC_DISP:
	; P1 Can be used for display pointer as it gets initialisd at the start of the main loop
	LDI VDU/256+1	; Set P1 to the middle of the last display line
	XPAH P1
	LDI 0xF5
	XPAL P1
	LD LCYCLE_H
	SR
	SR
	SR
	SR
	CCL
	ADI 0x30
	ST @1(P1)
	LD LCYCLE_H
	ANI 0x0F
	JZ NOT_TEST			; Test for demo mode if count reaches 100	(i.e. this nibble is not zero)
	XAE
	JP RESTORE_A		; Bit 7 not set so it's not in Demo mode
	XAE
	JMP RAND			; Randomise display and restart
RESTORE_A:	
	XAE
NOT_TEST:	
	CCL
	ADI 0x30
	ST @1(P1)	
	LD LCYCLE_L
	SR
	SR
	SR
	SR
	CCL
	ADI 0x30
	ST @1(P1)
	LD LCYCLE_L
	ANI 0x0F
	CCL
	ADI 0x30
	ST @3(P1)
	
; Scan for key press
KBD:
	LDI 0x0D		; point to MK14 display/keyboard
	XPAH P1   
	LDI 0x00
	XPAL P1
	LDI 0x00
	ST (P1)			; Set all display segments to off	
TEST_1:				; Change backgound cell character from '.' to ' '
    LD 1(P1)		; read keypad 0x0D01 (Key 1)
	ORI 0x0F		; Mask top 4 bits
	XRI 0x7F		; Result will be zero if key pressed
	JNZ TEST_D
	LDE				; get current character displayed
	XRI 0x0E		; 0x2E => 0x20
	XAE				; Store in E
TEST_D:
    LD 3(P1)		; read keypad 0x0D03 (Key D)
	ORI 0x0F		; Mask top 4 bits
	XRI 0xEF		; Result will be zero if key pressed
	JNZ TEST_GO
	LDE
	XRI 0x80		; Setting bit 7 of E indicates demo mode is active
	XAE
	LDI VDU/256+1	; Set P1 to the end of the last display line
	XPAH P1
	LDI 0xFA
	XPAL P1
	LD (P1)
	XRI 0x24		; Change a space to a D
	ST @1(P1)
	LD (P1)
	XRI 0x25		; Change a space to a E
	ST @1(P1)	
	LD (P1)
	XRI 0x2D		; Change a space to a M
	ST @1(P1)
	LD (P1)
	XRI 0x2F		; Change a space to a O
	ST @1(P1)		
	JMP FIN
TEST_GO:			; New Game with Random cell matrix
	LD 2(P1)		; read keypad 0x0D02 (Key GO)
	ORI 0x0F		; Mask top 4 bits
	XRI 0xDF		; Result will be zero if key pressed
    JZ RAND			; Key pressed 
FIN:
	RET P3

;------------------------------------------------------------------------------
; Restart game with a random cell matrix if GO is pressed
; This uses the random number (noise) generator from the SoC user manual
;------------------------------------------------------------------------------
RAND:
	LDI	GEN1+0x10/256
	XPAH P1
	LDI	GEN1+0x10\256  
    XPAL P1				; P1 now contains start address of Cell matrix
RAND0:
; Generate random cell matrix
	LD RNUM
	JNZ RAND1
	ILD RNUM			; Random number start value cannot be 0, so increment
RAND1:	
	RRL
	ST RNUM
	LD RNUM+1
	JNZ RAND2
	ILD RNUM+1			; Random number start value cannot be 0, so increment
RAND2:
	RRL
	ST RNUM+1
	CCL					; Ex-or of bits 1 and 2
	ADI 02				; In bit 2
	RR					; Rotate bit 2 to
	RR					; Bit 7
	RR
	ANI 0x87			; Put it in carry and
	CAS 				; Update flags
	ANI 0xFC			; Only store if value is <4
	JZ RAND3
	LDI 0x00
	JMP RAND4
RAND3:
	LDI 0x01
RAND4:	
	ST	@1(P1)			; Write cell location
	XPAH P1
	XRI	GEN1+0x1E0/256	; Check if P1_H is at upper limit
	JZ	RAND5			; If yes (zero) then check P1_L
	XRI	GEN1+0x1E0/256	; Restore P1_H
	XPAH P1
	JMP RAND0			; next cell
RAND5:
	XPAL P1
	XRI	GEN1+0x1E0\256	; Check if P1_L is at upper limit
	JZ RAND_RET			; If yes (zero) then fill has finished
	XRI	GEN1+0x1E0\256	; Restore P1_L
	XPAL P1
	LDI	GEN1+0x1E0/256	; Restore P1_H
	XPAH P1
	JMP	RAND0			; Next cell
RAND_RET:	
	JS P3,RE_ENTER			; Long jump to restart the program

RNUM	.DB 55			; random number variables, pre seeded
;RNUM1	.DB 03			; this byte undefined so it picks up random value from RAM at power on

;------------------------------------------------------------------------------
; Auto Start Address
	.OR 0xFFFE
	.DB ENTRY/256
	.DB ENTRY\256
;------------------------------------------------------------------------------	
	.END	



