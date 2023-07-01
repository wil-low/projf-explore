; *****************************************************************************
; MK14 Copy-Cat memory game
; Rev 1.0
; Written by Ian Reynolds Feb 2023 using SBASM 8060 assembler
;		https://www.sbprojects.net/sbasm/
;
; Requires continuous memory from 0200 to 07FF and base RAM at 0xF00
; Screen occupies 0x200 to 03FF and operates in Character mode
;
;=============================================================================================
; INSTRUCTIONS
; On start-up the screen shows the numeric keypad layout
; Select the display type using GO for a display that can show invertered characters
; or any other key for a 'standard' display
;
; Use Keys 1 to 9 to copy the displayed sequence
; Press GO to continue a game
; ABORT aborts the game (of course!)

; The game has 6 levels
;	Level 1: 5 number sequence
;	Level 2: 6 number sequence
;	Level 3: 7 number sequence
;	Level 4: 8 number sequence
;	Level 5: 9 number sequence
;	Level 6: 10 number sequence
;
; In Levels 1 to 5 you must correctly copy 7 random sequnces before moving onto the next level
; In Level 6 it's as many sequences (of 10 digits) as you can bare!
; You have 9 lives. If you get a sequence wrong you lose a life
;===============================================================================================
;
; Visit the UK Vintage Radio Forums, Vintage Computers, for updates
;
; https://www.vintage-radio.net/	 My username is Realtime
; *****************************************************************************

	.CR	SCMP
	.TF	COPYCAT.HEX,INT
;	.TF COPYCAT.BIN,bin
	.LF	COPYCAT.LST

;Game Constants
MK14_DISP	.EQ 0x015A		; MK14 Keyboard and display hardware address decode
MK14_KEYS	.EQ 0x0185		; Address in MK14 V2 monitor of the keyboard and display routine
DISPLAY		.EQ 0x0200		; Start of VDU frame store for graphics
PROG		.EQ 0x0200		; Start of program memory
LEVEL_PNT	.EQ 0x0367		; Points to LEVEL count on screen
SCORE_PNT	.EQ 0x0387		; Points to SCORE count on screen
LIVES_PNT	.EQ 0x03A7		; Points to LIVES count on screen
DISPL_LINE	.EQ	0x03C0		; Messages line of video display
INS8154		.EQ 0x0800		; MK14 I/O chip base address
VAR			.EQ 0x0F00		; Variables storage area
DISP_SEG	.EQ 0x0F00		; Address where display segment data is stored (used only to blank the 7 segment display)
CHAR_SPACE	.EQ 0x20		; " "
CHAR_EQUALS	.EQ 0x3D		; =
NO_LIVES	.EQ 0x09		; Number of lives (max allowed is 9)
NO_LOOPS	.EQ 0x07		; Number of sequences to be repeated for each level
CHAR_INV	.EQ 0x80		; This is the value that gets XORd with the selected tile to highlight it
START_SEQ	.EQ 0x05		; The number of digits in the starting sequence - should be 5 (other values only for testing)

; Game Variables - Start at 0x20 to allow P2 to point to the display and keyboard system variables
PRNG_L		.EQ 0x20		; Low byte of pseudo random number generator		
PRNG_H		.EQ 0x21		; High byte of pseudo random number generator		
PRNG_T		.EQ 0x22		; Temp result for pseudo random number generator	
COUNT1		.EQ 0X23		; General purpose counter
COUNT2		.EQ 0X24		; General purpose counter
COUNT3		.EQ 0x25		; General purpose counter	
DIGIT_DISP	.EQ 0x26		; Holds the digit to be displayed on screen
ARRAY1		.EQ 0x27		; Number sequence array
ARRAY2		.EQ 0x28		; Number sequence array
ARRAY3		.EQ 0x29		; Number sequence array
ARRAY4		.EQ 0x2A		; Number sequence array
ARRAY5		.EQ 0x2B		; Number sequence array
ARRAY6		.EQ 0x2C		; Number sequence array
ARRAY6		.EQ 0x2C		; Number sequence array
ARRAY7		.EQ 0x2D		; Number sequence array
ARRAY8		.EQ 0x2E		; Number sequence array
ARRAY9		.EQ 0x2F		; Number sequence array
ARRAY10		.EQ 0x30		; Number sequence array
P1H_TMP		.EQ 0x31		; Temporary store for P1
P1L_TMP		.EQ 0x32		; Temporary store for P1
SEQ_LEN		.EQ 0x33		; Determines the number of digits in a sequence
KEYPRESS_P	.EQ 0x34		; Holds the result of calling the MK14 monitor keyboard routine
LEVEL		.EQ 0x35		; Game Level (1-5)
SCORE_H		.EQ 0x36		; Score High Byte
SCORE_L		.EQ 0x37		; Score Low Byte
LIVES		.EQ 0x38		; Number of lives left
PLAYER_KEY	.EQ 0x39		; If non zero then indicates a player key press
NUM_LOOPS	.EQ 0x3A		; Number of sequences to be repeated at each level
DISP_INV	.EQ 0x3B		; if zero then the VDU supports inverse characters

	.OR	PROG
;================================================
; START UP SCREEN DEFINITION: This gets loaded into video ram as part of the program load
;================================================

	.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			;
	.DB 0x0D,0x0B,0x31,0x34,0x20,0x03,0x0F,0x10,0x19,0x03,0x01,0x14,0x20,0x20,0x16,0x31			; MK14 COPYCAT  V1
	.DB 0x20,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x20,0x20			;	@@@@@@@@@@@@@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x37,0x20,0x2E,0x20,0x38,0x20,0x2E,0x20,0x39,0x20,0x2E,0x20,0x20			;	@ 7 @ 8 @ 9 @	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x20,0x20			;	@@@@@@@@@@@@@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x34,0x20,0x2E,0x20,0x35,0x20,0x2E,0x20,0x36,0x20,0x2E,0x20,0x20			;	@ 4 @ 5 @ 6 @	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x20,0x20			;	@@@@@@@@@@@@@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x31,0x20,0x2E,0x20,0x32,0x20,0x2E,0x20,0x33,0x20,0x2E,0x20,0x20			;	@ 1 @ 2 @ 3 @	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20,0x20,0x2E,0x20,0x20			;	@	@	@	@	
	.DB 0x20,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x2E,0x20,0x20			;	@@@@@@@@@@@@@	
	.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			;
	.DB 0x20,0x0C,0x05,0x16,0x05,0x0C,0x3A,0x31,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			; LEVEL:1		 
	.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			;
	.DB 0x20,0x13,0x03,0x0F,0x12,0x05,0x3A,0x30,0x30,0x30,0x20,0x20,0x20,0x20,0x20,0x20			; SCORE:000		
	.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			;
	.DB 0x20,0x0C,0x09,0x16,0x05,0x13,0x3A,0x39,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			; LIVES:9 
	.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			;	
	.DB 0x09,0x06,0x20,0x19,0x0F,0x15,0x12,0x20,0x16,0x04,0x15,0x20,0x03,0x01,0x0E,0x20			; IF YOUR VDU CAN 
	.DB 0x04,0x09,0x13,0x10,0x0C,0x01,0x19,0x20,0x89,0x8E,0x96,0x85,0x92,0x93,0x85,0x20			; DISPLAY INVERSE 
	.DB 0x03,0x08,0x01,0x12,0x01,0x03,0x14,0x05,0x12,0x13,0x20,0x10,0x12,0x05,0x13,0x13			; CHARACTERS PRESS
	.DB 0x07,0x0F,0x2C,0x20,0x05,0x0C,0x13,0x05,0x20,0x01,0x0E,0x19,0x20,0x0B,0x05,0x19			; GO, ELSE ANY KEY


ENTRY:	
;================================================
; P2 is the variables pointer
;================================================	
	LDI VAR/256
	XPAH	P2
	LDI	VAR\256
	XPAL	P2
	
;================================================
; Set up INS8154 
; The following is for Realtime's 'Realview' MK14 VDU, using Port B for the control byte
; Other VDU's may require a different set up byte
;================================================

;IOPORT:
	; LDI	INS8154/256	 Base address of I/O device
	; XPAH	P3
	; LDI	INS8154\256
	; XPAL	P3
	; LDI	0xFF				; Set Port B as all outputs
	; ST 0x23(P3)	 			; Port B output definition register
	; LDI 0x60					; Set VDU control bits
	; ST 0x21(P3)	 			; Port B write address

	;	Port B bit 7 = PS3 - set to '0'		\
	;	Port B bit 6 = PS1 - set to '1'		\	Sets the video RAM address to 0x0200
	;	Port B bit 5 = PS2 - set to '1'		/	However, note that PS1 must not be physically connected
	;	Port B bit 4 = PS4 - set to '0'		/	to the VDU card as this line is controlled by the TOPPAGE signal
	;	Port B bit 3 = VDUOFF					- set to '0' for VDU on
	;	Port B bit 2 = Graphics/nCharacters 	- set to '0' for character mode
	;	Port B bit 1 = REVPAGES			 		- set to '0' for 0x200 at top of the screen (0x300 at bottom)
	;	Port B bit 0 = INVERT					- set to '0' for white video on black background

	;	LDI	0x00				; or lower FLAG2 for other card designs
	;	CAS		

START:
	; These variables at start of game
	LDI 0x00
	ST 0(P2)				; Clear 7 segment display segments
	ST 1(P2)
	ST 2(P2)
	ST 3(P2)
	ST 4(P2)
	ST 5(P2)
	ST 6(P2)
	ST 7(P2)
	ST SCORE_H(P2)
	ST SCORE_L(P2)
	ST PRNG_T(P2)
	LD PRNG_L(P2)			; Use RAM contents to set the seed for the PRNG
	JNZ START2
	ILD PRNG_L(P2)			; Seeded value can't be zero (PRNG_H might be zero, but not important so long as 16 bit PRNG is not zero)	

START2:
	LDI START_SEQ			; Number of digits in a sequence to start the game
	ST SEQ_LEN(P2)
	LDI NO_LIVES
	ST LIVES(P2)
	LDI NO_LOOPS			; Number of numeric sequences per level
	ST NUM_LOOPS(P2)
	
DISP_TYPE:
	;Press GO key to start in INVERSE Character mode
	JS P3,MK14_KEYS			; Scan keys
	NOP						; Do not delete - NOPs to compensate for return address from KEYS being 2 bytes more than needed
	NOP						; Do not delete
	LDE
	XRI 0x22				; Is it the GO key?
	JNZ DISP_T2				; If not is it 0
	LDI 0x00
	ST DISP_INV(P2)
	JMP MAIN_LOOP
DISP_T2:
	LDI 0xFF				; non-inverse character capable displays
	ST DISP_INV(P2)	

;---------------------------------------------------------------
; Main game loop
;---------------------------------------------------------------
MAIN_LOOP:	
	; Clear message line
    LDI	DISPL_LINE/256
	XPAH	P1
	LDI	DISPL_LINE\256 
    XPAL	P1
	LDI 0x40				; 3 lines of text to blank
	ST COUNT1(P2)
CLR_LINE:
	LDI CHAR_SPACE
	ST	@1(P1)
	DLD COUNT1(P2)
	JNZ CLR_LINE

LEVEL_LOOP:
;================================================
; Display Level, Score and Lives values
;================================================
	LDI	LEVEL_PNT/256
	XPAH P1
	LDI	LEVEL_PNT\256 
    XPAL P1
	LD SEQ_LEN(P2)
	CCL
	ADI 0x2C				; Convert to a numeric character 0x2C = 0x30 - 0x04;  Level = SEQ_LEN-0x04
	ST @0x23(P1)			; Display as LEVEL
	LD SCORE_L(P2)			; Get points lower byte (BCD counter)
	ANI 0x0F				; Mask off lower nibble
	ADI 0x30				; Convert to number character
	ST @-1(P1)				; Display number and increment pointer
	LD SCORE_L(P2)			; Reload points lower byte
	ANI 0xF0				; Mask off upper nibble
	SR						; Shift right 4 times
	SR
	SR
	SR
	ADI 0x30				; Convert to number character
	ST @-1(P1)				; Display number 
	LD SCORE_H(P2)			; Get high byte
	ANI 0x0F				; Mask lower nibble
	ADI 0x30				; Convert to number character
	ST @-1(P1)				; Dislay number
	LD LIVES(P2)
	ADI 0x30				; Convert to a numeric character
	ST 0x20(P1)				; Store On Screen
	
;================================================
; Fill array with random numbers in range 1 to 9
;================================================
	LDI VAR/256
	XPAH P1
	LDI ARRAY1
	XPAL P1					; P1 now points to start of ARRAY
	LDI 0x0A				; 10 array positions
	ST COUNT3(P2)
GET_PRNG:
	JS P3,PRNG
	LD PRNG_L(P2)
	ANI 0x0F				; Mask off top nibble
	JZ GET_PRNG				; If zero then get another PRNG
	CCL
	ADI 0xF6				; Subtract 10
	JP GET_PRNG				; If positive then number was greater than 9 so get another PRNG
	ADI 0x0A				; Restore value
	ST @1(P1)				; Store in ARRAY
	DLD COUNT3(P2)
	JNZ GET_PRNG

;================================================	
; Output number sequence to screen
;================================================
	LDI 0x00
	ST PLAYER_KEY(P2)		; Set as computer key selection
	LD SEQ_LEN(P2)			; Get number of digits to display
	ST COUNT3(P2)
	LDI VAR/256
	XPAH P1
	LDI ARRAY1
	XPAL P1					; P1 now points to start of ARRAY	
NEXT_DIGIT:
	LD @1(P1)				; Get value from ARRAY
	ST DIGIT_DISP(P2)
	XPAH P1					; Temporarily store P1, as it is used in NUM_FLASH routine
	ST P1H_TMP(P2)
	XPAL P1
	ST P1L_TMP(P2)
	JS P3,NUM_FLASH			; Flash on screen
	DLY 0xFF
	DLY 0xFF
	DLY 0xFF
	JS P3,NUM_FLASH
	DLY 0xFF
	DLY 0xFF
	DLY 0xFF
	LD P1L_TMP(P2)			; Restore P1
	XPAL P1
	LD P1H_TMP(P2)
	XPAH P1
	DLD COUNT3(P2)
	JNZ NEXT_DIGIT

;================================================
; Player repeats sequence
;================================================
	LDI 0xFF
	ST PLAYER_KEY(P2)		; Set as Player  key selection
	LD SEQ_LEN(P2)			; Get number of digits to display
	ST COUNT3(P2)
	LDI VAR/256
	XPAH P1
	LDI ARRAY1
	XPAL P1					; P1 now points to start of ARRAY
NEXT_KEY:	
	XPAH P1					; Temporarily store P1, as it is used in NUM_FLASH routine
	ST P1H_TMP(P2)
	XPAL P1
	ST P1L_TMP(P2)	
GET_KEY:
	JS P3,MK14_KEYS			; Scan keys - result returned in E
	NOP						; Do not delete - NOPs to compensate for return address from KEYS being 2 bytes more than needed
	NOP						; Do not delete
	XAE
	ST KEYPRESS_P(P2)		; Store player's DIGIT_DISP
	ST DIGIT_DISP(P2)
	; Range check key press - must be 1-9
	JZ GET_KEY				; If zero then wait for valid key press
	CCL
	ADI 0xF6				; Subtract 10
	JP GET_KEY				; If positive then number was greater than 9 so wait for a valid key press
	JS P3,NUM_FLASH			; Flash on screen
	DLY 0xFF
	DLY 0xFF
	JS P3,NUM_FLASH
	LD P1L_TMP(P2)			; Restore P1
	XPAL P1
	LD P1H_TMP(P2)
	XPAH P1
	LD @1(P1)				; Get value from ARRAY
	XOR KEYPRESS_P(P2)
	JNZ KEY_ERROR
	DLD COUNT3(P2)
	JNZ NEXT_KEY
	LDI 0x0A				; Determine delay before next sequence
	ST COUNT3(P2)
DLY_X:
	DLY 0xFF
	DLD COUNT3(P2)
	JNZ DLY_X
	LD SEQ_LEN(P2)			; Update SCORE (BCD) - SEQ_LEN*2 used as number of points for correct answer
	XRI 0x0A
	JNZ LT10				; SEQ_LEN is less than 10 so just add it in
	LDI 0x20				; Set points to 20 BCD (i.e 2 x SEQ length)
	CCL
	JMP GT9
LT10:	
	LD SEQ_LEN(P2)			; Restore value
	CCL
	DAD SEQ_LEN(P2)
GT9:
	DAD SCORE_L(P2)
	ST SCORE_L(P2)
	LDI 0x00
	DAD SCORE_H(P2)
	ST SCORE_H(P2)
	DLD NUM_LOOPS(P2)
	JZ NEXT_LEVEL
	JS P3,LEVEL_LOOP		; Long jump to start of this level game
NEXT_LEVEL:
	LDI NO_LOOPS			; Reset of numeric sequences per level
	ST NUM_LOOPS(P2)
	LD SEQ_LEN(P2)			; If SEQ_LEN = 10 then don't increase the level any further
	XRI 0x0A
	JZ LAST_LEVEL
	ILD SEQ_LEN(P2)
    LDI TO_LEVEL/256		; Get start address of game over text block
	XPAH P3
	LDI TO_LEVEL\256
	XPAL P3
	LDI DISPL_LINE/256
	XPAH P1
	LDI DISPL_LINE\256
	XPAL P1
NL1:
	LD @1(P3)				; Copy message to screen
	JZ NL2
	ST @1(P1)
	JMP NL1
NL2:
	LD  @-0x23(P1)			; Move to end of previous line
	LD SEQ_LEN(P2)
	CCL
	ADI 0x2C				; Convert to a numeric character 0x2C = 0x30 - 0x04;  Level = SEQ_LEN-0x04
	ST (P1)					; Display LEVEL	
	;Press GO to continue
KPRESS:
	JS P3,PRNG
	JS P3,MK14_KEYS			; Scan keys
	NOP						; Do not delete - NOPs to compensate for return address from KEYS being 2 bytes more than needed
	NOP						; Do not delete
	XAE
	XRI 0x22				; Is it the GO key?
	JNZ KPRESS				; If not wait for key press
LAST_LEVEL:
	JS P3,MAIN_LOOP
	
;================================================
; Player error
;================================================	
KEY_ERROR:   
    LDI LOST_LIFE/256 		; Get start address of Title text block
	XPAH P3
	LDI LOST_LIFE\256
	XPAL P3
	LDI DISPL_LINE/256
	XPAH P1
	LDI DISPL_LINE\256
	XPAL P1
KE2:
	LD @1(P3)				; copy it to screen
	JZ KE3
	ST @1(P1)
	JMP KE2		
KE3:	
	DLD LIVES(P2)
	JZ KE4
NEW_LIFE:
	JS P3,PRNG
	;Press GO key to start
	JS P3,MK14_KEYS			; Scan keys
	NOP						; Do not delete - NOPs to compensate for return address from KEYS being 2 bytes more than needed
	NOP						; Do not delete
	XAE
	XRI 0x22				; Is it the GO key?
	JNZ NEW_LIFE			; If not wait for key press
	JS P3,MAIN_LOOP
KE4:
    LDI GAME_OVER/256		; Get start address of game over text block
	XPAH P3
	LDI GAME_OVER\256
	XPAL P3
	LDI DISPL_LINE/256
	XPAH P1
	LDI DISPL_LINE\256
	XPAL P1
KE5:
	LD @1(P3)				; Copy message to screen
	JZ KE6
	ST @1(P1)
	JMP KE5	
KE6:
	JS P3,START				; Long jump to restart game

;================================================
; Messages
;================================================	
LOST_LIFE	.DB 0x19,0x0F,0x15,0x20,0x0C,0x0F,0x13,0x14,0x20,0x01,0x20,0x0C,0x09,0x06,0x05,0x21			; YOU LOST A LIFE!
SPACES1		.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			; Blank line
GO_KEY1		.DB 0x10,0x12,0x05,0x13,0x13,0x20,0x14,0x08,0x05,0x20,0x07,0x0F,0x20,0x0B,0x05,0x19,0x00	; PRESS THE GO KEY
GAME_OVER	.DB 0x2A,0x2A,0x20,0x07,0x01,0x0D,0x05,0x20,0x20,0x0F,0x16,0x05,0x12,0x20,0x2A,0x2A    	 	; ** GAME  OVER **
SPACES2		.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			; Blank line
GO_KEY2		.DB 0x10,0x12,0x05,0x13,0x13,0x20,0x14,0x08,0x05,0x20,0x07,0x0F,0x20,0x0B,0x05,0x19,0x00	; PRESS THE GO KEY
TO_LEVEL	.DB 0x20,0x20,0x07,0x0F,0x14,0x0F,0x20,0x0C,0x05,0x16,0x05,0x0C,0x20,0x20,0x20,0x20			;   GOTO LEVEL  
SPACES3		.DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20			; Blank line
GO_KEY3		.DB 0x10,0x12,0x05,0x13,0x13,0x20,0x14,0x08,0x05,0x20,0x07,0x0F,0x20,0x0B,0x05,0x19,0x00	; PRESS THE GO KEY 

NUM_FLASH:
; *****************************************************************************
; Subroutine to invert tile on screen
; This subroutine is intended for VDU modules that have character inversion
; controlled by bit7 of the character code
; On entry, Reg A contains the tile to be inverted
; If it's a player response then only invert the central number
; *****************************************************************************
	; Calculate the actual display offset and store in P1
	LD DIGIT_DISP(P2)
	CCL
	ADI 0x0A				; point to offset in the lookup table
	XAE
	LD E(P0)				; Get value from look up table, relative to P0
	XPAL P1
	LDI 0x02	
	XPAH P1					; P1 now points to the correct offset in display memory - 02xx
	LD DISP_INV(P2)			; If DISP_INV is zero then display supports inverse video
	JNZ FLASH
	JMP INVERT
VECTOR:
	.DB 0xF2,0xF6,0xFA,0x92,0x96,0x9A,0x32,0x36,0x3A
	; Invert the selected number
INVERT:
	LD PLAYER_KEY(P2)
	JNZ	CENTRE_DIGIT		; If not zero then it's a player key press
	LDI 0x05				; 5 rows to invert
	ST COUNT1(P2)
ROWPOS:
	LDI 0x03				; 3 characters in a row#
	ST COUNT2(P2)
CHARPOS:
	LD (P1)
	XRI 0x80
	ST @0x01(P1)
	DLD COUNT2(P2)
	JNZ CHARPOS
	LD @0x0D(P1)
	DLD COUNT1(P2)
	JNZ ROWPOS
	RET P3
CENTRE_DIGIT:
	LD @0x21(P1)			; point to digit
	LD (P1)
	XRI 0x80
	ST (P1)
	RET P3

; *****************************************************************************
; Subroutine to flash a tile on screen
; This subroutine is intended for VDU modules that don't have character inversion
; controlled by bit7 of the character code
; On entry, Reg A contains the tile number to be flashed
; *****************************************************************************
FLASH:
	LD 0x20(P1)				; point to left of digit
	XRI CHAR_SPACE
	JZ FL1					; If cell contains a space then display "="
	LDI CHAR_SPACE			; If cell doesn't contain a spoace then display " "
	JMP FL2
FL1:
	LDI CHAR_EQUALS
FL2:
	XAE
	LDE
	ST 0x20(P1)
	ST 0x22(P1)	
	LD PLAYER_KEY(P2)
	JNZ	FL3					; If not zero then it's a player key press
	LDE
	ST 0x11(P1)	
	ST 0x31(P1)
FL3:
	RET P3

; *****************************************************************************
; Psuedo Random Number Generator subroutine
; Generate next number in the 16 bit PRNG sequence
;
;           High Byte               Low Byte
;        ---------------       -----------------
;   |-> | 15 14 -----> 8 |--> | 7 6 5 4 3 2 1 0 |     ---shift right --->
;   |    ---------------       -----------------
;   |                               |   | |   |
;   |                          /{{--|   | |   |
;   -<---------------------XOR/ {{------| |   |
;                             \ {{--------|   |
;                              \{{------------|
; *****************************************************************************
	
PRNG:	
	LD PRNG_L(P2)				; Code up to PRNG_5 XORs individual bits of PRNG_L
	XAE
	LDE
	ANI 0x01					; Bit 0	
	JZ PRNG_1
	LD PRNG_T(P2)				; PRNG_T stores the developing XOR result
	XRI 0x01
	ST PRNG_T(P2)
PRNG_1:
	LDE
	ANI 0x04					; Bit 2
	JZ PRNG_2
	LD PRNG_T(P2)
	XRI 0x01
	ST PRNG_T(P2)
PRNG_2:
	LDE
	ANI 0x08					; Bit 3 
	JZ PRNG_3
	LD PRNG_T(P2)
	XRI 0x01
	ST PRNG_T(P2)
PRNG_3:
	LDE
	ANI 0x20					; Bit 5 
	JZ PRNG_4
	LD PRNG_T(P2)
	XRI 0x01
	ST PRNG_T(P2)				; PRNG_T bit 0 now holds XOR of the 4 bits
PRNG_4:
	CCL							; Clear Carry Flag
	LD PRNG_T(P2)
	JZ PRNG_5
		SCL						; If PRNG_T is not zero then set the carry flag
PRNG_5:
	LD PRNG_H(P2)
	ANI 0x01
	ST PRNG_T(P2)				; Store lsb of PRNG_H in PRNG_T for later
	LD PRNG_H(P2)
	SRL							; Rotate Carry flag into A and store in PRNG_H
	ST PRNG_H(P2)	
 	CCL
	LD PRNG_T(P2)				; Determine state of PRNG_H bit 0 (as stored in PRNG_T)
	JZ PRNG_7
PRNG_6:
	SCL
PRNG_7:
	LD PRNG_L(P2)
	SRL							; Shift bit 0 of PRNG_H into bit 7 of PRNG_L
	ST PRNG_L(P2)				; 16 bit shift completed
	RET P3

EXEC_ADR:						; Autostart vetctor - Comment out these lines when generating a .bin file
	.NO 0xFFFE
	.DB ENTRY/256
	.DB ENTRY\256
