	.CR	SCMP
	.TF	solitaire_v1o.hex,INT
;	.TF solitaire_v1o.BIN,bin
	.LF	solitaire_v1o.lst
	
; *****************************************************************************
; Loads at 0x0400 and 0F3F and 0BCC, Executes at 0x0400
; *****************************************************************************
	
;Game Constants
PROM			.EQ 0x0051
CROM			.EQ 0x010B		; Address of character ROM in SCIOSv3
MK14_KEYS		.EQ 0x0185		; Address of keyboard and display routine in SCIOSv3
DISP_GR			.EQ 0x0200		; Start of VDU frame store for graphics
DISP_CARDS		.EQ 0x01FE		; Start of VDU frame store for Cards graphics

PROG1			.EQ 0x0400		;Start of program memory
PROG2			.EQ 0x0F3F		;Program sub routines
PROG3			.EQ 0x0BCC		;Program sub routines

VAR_0880		.EQ 0x0880		;Ascii value of cards
VAR_088E		.EQ 0x088E		;Card Suits
VAR_0892		.EQ 0x0892		;Initial values of Foundation
VAR_0896		.EQ 0x0896		;Pack of Cards
VAR_08CB		.EQ 0x08CB		;52 Random Numbers Store

KBD_DISP		.EQ 0x0D00		;MK14 Keyboard and display hardware address decode

VAR_0B00		.EQ 0x0B00		;Column storage pointers
VAR_0B10		.EQ 0x0B10		;Column storage 
VAR_0BB4		.EQ 0x0BB4		;Foundation Variables
VAR_SWAP		.EQ 0x0BBC		;Swap Area

VAR_0F00		.EQ 0x0F00		;Variables storage area
VAR_0F40		.EQ 0x0F40		;Program sub routines


;  Variables
	.OR VAR_0F00


DISPLAY_0	.EQ 0x08
DISPLAY_1	.EQ 0x07
DISPLAY_2	.EQ 0x06
DISPLAY_3	.EQ 0x05
DISPLAY_4	.EQ 0x04
DISPLAY_5	.EQ 0x02
DISPLAY_6	.EQ 0x01
DISPLAY_7	.EQ 0x00

COL_POS		.EQ 0x1D
DISP_H		.EQ 0x1E		;Could reuse PRNG_H
DISP_L		.EQ 0x1F		;Could reuse PRNG_L
TEMP		.EQ 0x20		;Used in Loops as counter
COUNT		.EQ 0x21
PACK_COUNT	.EQ 0x22
MOVE_COUNT	.EQ 0x23
VALID		.EQ 0x24		;Valid Move
CARD		.EQ 0x25
CARDNUM		.EQ 0x26		;Card Number 1 to 52
C_SUIT		.EQ 0x27		;Card Suit
C_NUM		.EQ 0x28		;Card Number 1 to 13
C_HIDE		.EQ 0x29
C_N_ASC		.EQ 0x2A		;Asc value for card number
C_S_ASC		.EQ 0x2B		;Asc value for card suit
PRNG_L		.EQ 0x2C		;Low byte of pseudo random number generator
PRNG_H		.EQ 0x2D		;High byte of pseudo random number generator
PRNG_T		.EQ 0x2E		;Temp result for pseudo random number generator
COL			.EQ 0x2F
COL_1		.EQ 0x30
COL_8		.EQ 0x31
ROW			.EQ 0x32
KEYPRESS	.EQ 0x33
KEYPRESS_1	.EQ 0x34
KEYPRESS_2	.EQ 0x35
FOUNDATION	.EQ 0x36
FOUNDATION1	.EQ 0x37
FOUNDATION2	.EQ 0x38
CARD1_VAL	.EQ 0x39
CARD2_VAL	.EQ 0x3A
CARD1_BLACK	.EQ 0x3B
CARD2_BLACK	.EQ 0x3C
CARD1_SUIT	.EQ 0x3D
CARD2_SUIT	.EQ 0x3E


	.OR DISP_GR
	.HS B13DB23DB33DB43DB53DB63DB73D3D3D
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 2020202020202020202020202020B820
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 2020202020202020202020202020B920
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020208120
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020208220
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020208320
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020208420
	.HS 20202020202020202020202020203A20
	.HS 20202020202020202020202020203A20

	.OR VAR_0B00
	;	000102030405060708090A0B0C0DSWap
	.HS 00101D2B3A4A5B6D809AB4B6B8BABCF0
	.OR VAR_0880
	.HS 20013233343536373839140A110B		;Original Card Character
	;.HS 200132333435363738391F0A110B		;RealView Card Character
	.OR VAR_088E
	;.HS 271B1D00	;RealView Card Characters 		S H C D Suits
	.HS 13080304	;Original VDU Card Characters 	S H C D Suits 
	.OR VAR_0892
	.HS 40506070							;Foundation starting values	
	.OR VAR_0896
	.HS 000102030405060708090A0B0C0D		;Cards
	.HS 1112131415161718191A1B1C1D
	.HS 2122232425262728292A2B2C2D
	.HS 3132333435363738393A3B3C3D

	
	.OR PROG1


ENTRY:	
;===================================================================
;P2 is variables pointer 0F00
;===================================================================

	LDI VAR_0F00/256
	XPAH P2
	LDI VAR_0F00\256
	XPAL P2

;---------------------------------------------------------------------
CLEAR_MEMORY:
	
	LDI VAR_0B10/256
	XPAH P1
	LDI VAR_0B10\256
	XPAL P1				; P1 now contains column data

	LDI 0x44
	ST TEMP(2)
	
CLEAR_MEM_0B00:
	LDI 0x00			; Clear Memory 0x00
	ST @1(P1)
	ILD TEMP(2)
	JNZ CLEAR_MEM_0B00

	ST FOUNDATION2(2)
;---------------------------------------------------------------------
;Set Foundation to initial values
	LDI VAR_0BB4/256
	XPAH P1
	LDI VAR_0BB4\256			;Place Foundation starting card
	XPAL P1

	LDI	VAR_0892/256
	XPAH P3
	LDI	VAR_0892\256  
    XPAL P3						;P3 contains pointer to header info

	LDI 0x04
	ST TEMP(2)

LOOP0:
	LDI 0x01
	ST @1(P1)
	LD @1(P3)
	ST @1(P1)
	DLD TEMP(2)
	JNZ LOOP0

;======================================================================

	LDI VAR_08CB/256
	XPAH P1
	LDI VAR_08CB\256
	XPAL P1				; P1 now contains start address of Random Cards

;----------------------------------------------------------------------

	LDI 0x00
	ST PRNG_T(P2)
	LD PRNG_L(P2)   ; Use RAM contents to set the seed for the PRNG
	JNZ SEED_EXIT
	ILD PRNG_L(P2)  ; Seeded value can't be zero (PRNG_H might be zero,
					;but not important so long as 16 bit PRNG is not zero)	

SEED_EXIT:
	LDI 0
	ST TEMP(2)
	
SHUFFLE:
;=======================================================================
					; In the main body of your game	
    ;JS P3,PRNG      ; Call subroutine to update PRNG_L and PRNG_H
	                ; Test PRNG_L. if 0 or >52 then call subroutine again
	                
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
    LD PRNG_L(P2)             ; Code up to PRNG_5 XORs individual bits of PRNG_L
	XAE
	LDE
	ANI 0x01                  ; Bit 0   
	JZ PRNG_1
	LD PRNG_T(P2)             ; PRNG_T stores the developing XOR result
	XRI 0x01
	ST PRNG_T(P2)
PRNG_1:
    LDE
    ANI 0x04                  ; Bit 2
    JZ PRNG_2
	LD PRNG_T(P2)
	XRI 0x01
	ST PRNG_T(P2)
PRNG_2:
    LDE
    ANI 0x08                  ; Bit 3 
    JZ PRNG_3
	LD PRNG_T(P2)
	XRI 0x01
	ST PRNG_T(P2)
PRNG_3:
    LDE
    ANI 0x20                  ; Bit 5 
    JZ PRNG_4
	LD PRNG_T(P2)
	XRI 0x01
	ST PRNG_T(P2)             ; PRNG_T bit 0 now holds XOR of the 4 bits
PRNG_4:
	CCL                       ; Clear Carry Flag
	LD PRNG_T(P2)
	JZ PRNG_5
	SCL                       ; If PRNG_T is not zero then set the carry flag
PRNG_5:
    LD PRNG_H(P2)
    ANI 0x01
    ST PRNG_T(P2)             ; Store lsb of PRNG_H in PRNG_T for later
    LD PRNG_H(P2)
	SRL                       ; Rotate Carry flag into A and store in PRNG_H
    ST PRNG_H(P2)	
 	CCL
	LD PRNG_T(P2)             ; Determine state of PRNG_H bit 0 (as stored in PRNG_T)
	JZ PRNG_7
PRNG_6:
	SCL
PRNG_7:
	LD PRNG_L(P2)
	SRL                      ; Shift bit 0 of PRNG_H into bit 7 of PRNG_L
	ST PRNG_L(P2)            ; 16 bit shift completed

;=======================================================================

	JZ SHUFFLE		; Zero not required
	ADI 0xcb		; Check Number < 53 (0x33)
	CSA				;Copy Status to AC
	ANI 0x80		;Check CY/L flag of status
	JNZ SHUFFLE		;Jump if number above 52
	LD TEMP(2)
	JZ FIRST		;Jump if first random number.
	
	LDI 0
	ST COUNT(2)
	
NEXT_COUNT:
	ILD COUNT(2)
	XAE
	LD -128(P1)	
	XOR PRNG_L(P2)
	JZ SHUFFLE
	LD COUNT(2)
	XOR TEMP(2)
	JNZ NEXT_COUNT

FIRST:
	ILD TEMP(2)
	XAE
	LD PRNG_L(P2)	; Random Number
	ST -128(P1)		; Place Card
	LD TEMP(2)
	XRI 0x34		;Check we have 52 cards
	JNZ SHUFFLE 
	
;=======================================================================
; We have 52 random numbers stored at 08CB
;=======================================================================

	LDI VAR_0896/256
	XPAH P3
	LDI VAR_0896\256
	XPAL P3				;VAR_0896		Pack of Cards Of Cards
	
	LDI 0x01			
	ST CARDNUM(2)
	
LOOP9:
	LD CARDNUM(2)
	XAE
	LD -128(P1)			;Load Random Number
	XAE
	LD -128(P3)			;Load Card
	ST CARD(2)
	
	LD CARDNUM(2)
	XAE
	LD CARD(2)
	ST -128(P1)			;Replace Random Number with card
	
	ILD CARDNUM(2)
	XRI 0x35			;0x34 = 52 cards 0x1C = 24 cards
	JNZ LOOP9	
	

;---------------------------------------------------------------------
	
	LDI 0x01			
	ST COL(2)
	ST COL_1(2)
	ST CARDNUM(2)
	
	LDI 0x00
	ST C_HIDE(2)
		
LOOP1:	
	LDI VAR_08CB/256
	XPAH P1
	LDI VAR_08CB\256  
	XPAL P1					;VAR_08CB		Random Numbers 

	LD CARDNUM(2)
	XAE
	LD -128(P1)
	OR C_HIDE(2)
	ST CARD(2)
	
	JS P3,ADD_CARD

	LDI 0x80
	ST C_HIDE(2)
	
CHECK_COL:
	LD COL(2)
	XRI 0x08
	JZ NEXT_CARDNUM			;Jump if column 8

	ILD COL(2)				;Move to next column
	XRI 0x08
	JNZ NEXT_CARDNUM		;Jump if not column 8 after increament
	
	LDI 0x00
	ST C_HIDE(2)			;Unhide last card in column
	ILD COL_1(2)			;If not column 8 increment column
	ST COL(2)
	XRI 0x08
	JNZ NEXT_CARDNUM
	
	LDI 0x08
	ST COL(2)

NEXT_CARDNUM:
	ILD CARDNUM(2)
	XRI 0x35				;0x34 = 52 cards 0x1C = 24 cards
	JNZ LOOP1

	LDI 0x18
	ST PACK_COUNT(2)		;Starting number of cards in Pack
	


	
;======================================================================
;---------------------------Main Loop----------------------------------
;-------------------------Display Cards First--------------------------
;======================================================================

DISPLAY_CARDS:

	CCL
	
	LDI VAR_0F00/256
	XPAH P2
	LDI VAR_0F00\256
	XPAL P2

	LDI 0x01
	ST COL(2)

	LDI 0x10
	ST COL_POS(2)

NEXT_COL1:
	LDI 0x00
	ST CARDNUM(2)

	LDI 0x01
	ST ROW(2)
	
	LDI 0x02
	XPAH P1
	LD COL_POS(2)
	XPAL P1

NEXT_CARD_IN_ROW:

	ILD CARDNUM(2)

	XPAH P1
	ST	DISP_H(2)		;Save Cursor position so P1 can be reused
	XPAL P1
	ST	DISP_L(2)

	LDI VAR_0B00/256
	XPAH P1
	LDI VAR_0B00\256
	XPAL P1
	
	LD COL(2)
	XAE
	LD -128(P1)
	XPAL P1				;Set P1 to column pointer 
	
	LD @0(P1)
	ST COUNT(2)
	
	LD CARDNUM(2)
	XAE
	LD -128(P1)
	ST CARD(2)
	
	JS P3,GET_CARD_DETAILS

;----------------------------------------------------------------------
	
	LD DISP_H(2)		;Get Cursor Position
	XPAH P1
	LD DISP_L(2)
	XPAL P1				;P1 contains location of cursor
	
	LD COUNT(2)
	JZ BLANK_ROW		;No cards in column

	LD C_HIDE(2)
	JNZ HIDE_CARD
	
SHOW_CARD:
	;CCL				;Not sure if required
	LD COUNT(2)
	ADI 0x75			;Check for more than 11 cards in column
	JP LONG_COLUMN		;Jump if less than 11 cards in column
	JMP SHORT_COLUMN
	
LONG_COLUMN:
	LD CARDNUM(2)
	XRI 0x01
	JZ SHORT_COLUMN		; Place seperator before cards except 1st Card
	LDI 0x20			; Space Character
	ST	@16(P1)			; Place Card	
	ILD ROW(2)	
	
SHORT_COLUMN:		
	LD	C_N_ASC(2)
	ST	@16(P1)			; Place Card
	ILD ROW(2)

HIDE_CARD:	
	LD	C_S_ASC(2)		; + character
	ST	@16(P1)			; Place Card
	ILD ROW(2)	

	LD CARDNUM(2)	
	XOR COUNT(2)
	JNZ NEXT_CARD_IN_ROW
	
;********************************************************************	

BLANK_ROW:				;Blank remaing rows in column
	ILD ROW(2)
	LDI 0x20
	ST	@16(P1)			;Place space character
	CCL
	LD ROW(2)
	ADI 0x61
	JP BLANK_ROW
	

NEXT_COL:
	ILD COL_POS(2)		;move cursor 2 places to the right
	ILD COL_POS(2)
	ILD COL(2)
	XRI 0x08			;Number of columns 0x08
	JNZ NEXT_COL1


;---------------------------------------------------------------------
;Display Column 8 to D
	;Col(2) should equal 0x08 at this point
		
	LDI 0x01
	ST ROW(2)	
	
	LDI	0xFE
	ST FOUNDATION(2)	;FE=8,FF=9,00=A,01=B,02=C;03=D

LOOP4:
	LDI VAR_0B00/256
	XPAH P1
	LDI VAR_0B00\256
	XPAL P1

	LD COL(2)
	XAE
	LD -128(P1)
	XPAL P1				;Set P1 to = 0x0B Card Number 
	
	LDI 0x01
	XAE
	
	LD FOUNDATION(2)
	JNZ NEXT2
	ILD ROW(2)
		
NEXT2:		
	LD FOUNDATION(2)
	JP GET_CARD
	LD @0(P1)			;Number of cards in column
	XAE
	
GET_CARD:	
	LD -128(P1)			;Load Card at 0x0B??
	ST CARD(2)

	JS P3,GET_CARD_DETAILS
	
	LDI	DISP_GR/256		;DISP_GR		.EQ 0x0200 
	XPAH P1
	LDI	0x0F			;020F used due to header
	XPAL P1				; P1 now contains start address of cards display 020F

	LD ROW(2)
	ST TEMP(2)
YPOS10:
	LD @0x40(P1)
	DLD TEMP(2)
	JNZ YPOS10
	
	LD	C_N_ASC(2)
	ST	@16(P1)			; Place Card
	LD	C_S_ASC(2)		; + character
	ST	@0(P1)			; Place Card
	
	ILD FOUNDATION(2)
	ILD ROW(2)
	ILD COL(2)
	XRI 0x0E			;
	JNZ LOOP4


;======================================================================
;----------------------Get User Input----------------------------------
;======================================================================

GET_KEY_1:
	CCL
	JS P3,MK14_KEYS
	NOP
	NOP
	XAE
	ST KEYPRESS(2)
	ST KEYPRESS_1(2)
	ST DISPLAY_4(2)
	JZ GET_KEY_1
	
;-------------------Moved to preserve for debugging
	
	LDI 0x00
	ST FOUNDATION(2)
	ST FOUNDATION1(2)		;Reset Foundation Key to zero (False)
	ST FOUNDATION2(2)
	ST COL_8(2)				;Reset Col_8 flag to zero (False)
	ST VALID(2)				;Set valid to Zero (False)
	
	
;Clear 7 Segmant display --------------------------------------------

	ST DISPLAY_0(2)
	ST DISPLAY_1(2)
	ST DISPLAY_2(2)
	ST DISPLAY_3(2)
	ST DISPLAY_6(2)
	ST DISPLAY_7(2)

;-------------------------------------------------------------	

	LD KEYPRESS_1(2)
	XRI 0x08				;Check for digit 8 Take Card From Pack
	JZ TAKE_CARD
	
	LD KEYPRESS_1(2)
	ADI 0x72				;Check for digit below d
	JP KEY1_7
	JMP GET_KEY_1

;---------------------------------------------------------------------
TAKE_CARD:
	LD PACK_COUNT(2)
	JNZ TAKE_NEXT_CARD

MOVE_PACK:	
	LDI 0x09
	ST COL(2)
	JS P3,DELETE_CARD
	LDE
	ST PACK_COUNT(2)

	LDI 0x08
	ST COL(2)
	JS P3,ADD_CARD
	
	LD PACK_COUNT(2)
	JNZ MOVE_PACK
	
TAKE_NEXT_CARD:	
	LDI 0x08
	ST COL(2)
	JS P3,DELETE_CARD
	LDE
	ST PACK_COUNT(2)

	LDI 0x09
	ST COL(2)
	JS P3,ADD_CARD

;DISPLAY_CARDS_JUMP:
	LDI DISPLAY_CARDS/256		;Get Display Cards address to far to jump
	XPAH P3
	LDI DISPLAY_CARDS\256
	XPAL P3
	LD @-1(3)					;Adjust P3 to set correct jump address
	XPPC 3
	
;----------------------------------------------------------------------
KEY1_7:
	
	LD KEYPRESS(2)
	ADI 0x76					;Set Suit Flag used by column count
	JP KEY1_NOT_FOUNDATION		;Jump if positive
	LDI 0x01
	ST FOUNDATION(2)
	ST FOUNDATION1(2)
	
KEY1_NOT_FOUNDATION:

	JS P3,GET_CARD_FROM_KEYPRESS
	
	LD CARD2_VAL(2)
	ST CARD1_VAL(2)
	LD CARD2_SUIT(2)
	ST CARD1_SUIT(2)
	LD CARD2_BLACK(2)
	ST CARD1_BLACK(2)


GET_KEY_2
	JS P3,MK14_KEYS
	NOP
	NOP
	XAE
	ST KEYPRESS(2)
	ST KEYPRESS_2(2)
	ST DISPLAY_7(2)
	JZ GET_KEY_2
	
	LDI 0x00
	ST FOUNDATION(2)

;Check Foundation key pressed
	LD KEYPRESS(2)
	ADI 0x76						;Set Suit Flag used by column count
	JP KEY2_NOT_FOUNDATION			;Jump if positive
	LDI 0x01
	ST FOUNDATION(2)
	ST FOUNDATION2(2)				;Key A to D indicate foundation
	
KEY2_NOT_FOUNDATION:
	
	JS P3,GET_CARD_FROM_KEYPRESS
	
;---------------------------------------------------------------------
CHECK_VALID_MOVE1:					;Simple valid check
	CCL
	LD CARD1_VAL(2)
	ADI 0x01
	XOR CARD2_VAL(2)
	JNZ CHECK_VALID_MOVE2			;Not valid so check Valid move 2
	
CHECK_COLOUR:	
	LD CARD1_BLACK(2)
	XOR CARD2_BLACK(2)
	JZ CHECK_VALID_MOVE2			;Not valid so check Valid move 2
	LDI 0x02						;Valid Move
	ST VALID(2)
	JMP VALID_MOVE

;---------------------------------------------------------------------
CHECK_VALID_MOVE2:					;Check move card to foundation
	LD FOUNDATION2(2)
	JZ NOT_VALID_MOVE2
	CCL
	LD CARD2_VAL(2)
	ADI 0x01
	XOR CARD1_VAL(2)
	JNZ NOT_VALID_MOVE2
	
CHECK_SAME_SUIT:	
	LD CARD1_SUIT(2)
	XOR CARD2_SUIT(2)
	JNZ NOT_VALID_MOVE2
	LDI 0x04						;Valid Move 1 = True
	ST VALID(2)
	JMP VALID_MOVE

;---------------------------------------------------------------------
NOT_VALID_MOVE2:
	JS P3,CHECK_VALID_MOVE3			;Check for King on empty column
	LD VALID(2)
	JZ CHECK_MULTI_MOVE
	
VALID_MOVE:	

	LD KEYPRESS_1(2)
	ST COL(2)
	JS P3,DELETE_CARD
	
	LD KEYPRESS_2(2)
	ST COL(2)
	JS P3,ADD_CARD

	;Check if game has finished, no room to add additional code

DISPLAY_CARDS_JUMP:
	LDI DISPLAY_CARDS/256	;Get Display Cards address to far to jump
	XPAH P3
	LDI DISPLAY_CARDS\256
	XPAL P3
	LD @-1(3)				;Adjust P3 to set correct execution address
	XPPC 3

;---------------------------------------------------------------------
END:

    LDI PROM/256	  		;Get start address of SCIOS
	XPAH P3
	LDI PROM\256
	XPAL P3
	XPPC 3
	
;----------------------------------------------------------------------	
CHECK_MULTI_MOVE:
	
	LD COL_8(2)
	JNZ	DISPLAY_CARDS_JUMP

	JS P3,COPY_CARDS
	
	JS P3,CHECK_VALID_MOVE3			;Check for King on empty column
	LD VALID(2)
	JNZ VALID_MOVE2
	
	JS P3,CALCULATE_CARDS_TO_MOVE
	LD VALID(2)						;Valid holds valid move
	JZ DISPLAY_CARDS_JUMP			;Not Valid move skip update	
		
VALID_MULTI_MOVE:

	LD MOVE_COUNT(2)
	XOR COUNT(2)
	JZ VALID_MOVE2					;Confirm we have at least 1 card to move
	
	LDI 0x0E
	ST COL(2)
	JS P3,DELETE_CARD
	
	DLD MOVE_COUNT(2)
	JMP VALID_MULTI_MOVE
	
VALID_MOVE2:
	LD KEYPRESS_1(2)
	ST COL(2)
	JS P3,DELETE_CARD
	
	LDI 0x0E
	ST COL(2)
	JS P3,DELETE_CARD
	
	LD KEYPRESS_2(2)
	ST COL(2)
	JS P3,ADD_CARD
	
	DLD MOVE_COUNT(2)
	JNZ VALID_MOVE2
	JMP DISPLAY_CARDS_JUMP
	
;======================================================================
;======================================================================
DELETE_CARD:
	LDI VAR_0B00/256
	XPAH P1
	LDI VAR_0B00\256
	XPAL P1
	
	LD COL(2)
	XAE
	LD -128(P1)
	XPAL P1					;Set P1 to = 0x0B Card Number 
	
	LD FOUNDATION1(2)
	JNZ DELETE_CARD_FOUNDATION		;Check if foundation, if so store card at plus 1

NOT_FOUNDATION2:
	LD @0(P1)				;Number of cards in column
	XAE
	LD -128(P1)				;Load Card at 0x0B?? 
	ANI 0x7F 
	ST CARD(2)
	LDI 0x00
	ST -128(P1)
	
	DLD @0(P1)				;Reduce Number of cards in column by 1
	XAE						;Need to check zero cards left in column
	
	LD COL(2)
	XRI 0x08				;Check column not 8 do not show col 8
	JZ DELETE_CARD_RETURN

	LD -128(P1)				;Load Card at 0x0B?? 
	ANI 0x7F 				;Unhide card
	ST -128(P1)

DELETE_CARD_RETURN:
	RET P3

DELETE_CARD_FOUNDATION:
	LDI 0x01
	XAE
	LD -128(P1)		
	ST CARD(2)
	DLD CARD(2)
	ST -128(P1)
	ILD CARD(2)
	DLD @0(P1)
	RET P3

;======================================================================		
GET_CARD_FROM_KEYPRESS:
	LDI VAR_0B00/256
	XPAH P1
	LDI VAR_0B00\256
	XPAL P1
	
	LD KEYPRESS(2)			;Check if keypress is > 8 (Col 8)
	ADI 0x78
	JP NOT_COL_8				;Jump if positive
	LDI 0x01					;Set COL_8 flag to True
	ST COL_8(2)
	
NOT_COL_8:	
	LD KEYPRESS(2)
	XAE
	LD -128(P1)
	XPAL P1				;Set P1 to = 0x0B Card Number 

	LDI 0x01			;Number of cards in column
	XAE

	LD FOUNDATION(2)
	JNZ FOUNDATION_COL
	
	LD @0(P1)			;Number of cards in column
	XAE
	
FOUNDATION_COL:	
	LD -128(P1)			;Load Card at 0x0B??  
	ST CARD(2)
	
	ANI 0x0F
	ST CARD2_VAL(2)
	LD CARD(2)
	ANI 0x30
	ST CARD2_SUIT(2)	
	ANI 0x10						;5th Bit Set for black card
	ST CARD2_BLACK(2)
	
	RET P3
	
;======================================================================
;======================================================================
;======================================================================
;======================================================================
	.OR PROG2

CHECK_VALID_MOVE3:					;Check for King on empty column
		
	LD CARD1_VAL(2)
	XRI 0x0D
	JNZ CHECK_VALID_MOVE3_RETURN
	
CHECK_NO_CARDS_IN_COLUMN:	
	LD CARD2_VAL(2)
	JNZ CHECK_VALID_MOVE3_RETURN
	LDI 0x08						;Valid Move
	ST VALID(2)

CHECK_VALID_MOVE3_RETURN:
	RET P3

COPY_CARDS:

	LDI VAR_SWAP/256
	XPAH P1
	LDI VAR_SWAP\256
	XPAL P1

	LDI 0x00
	ST @0(P1)			;Set Copy are to zero

	LDI VAR_0B00\256
	XPAL P1
	
	LD KEYPRESS_1(2)
	XAE
	LD -128(P1)
	XPAL P1				;Set P1 to = 0x0B Card Number 
	
	LD @0(P1)
	ST COUNT(2)			;Number of cards in column

LOOP6:
	LDI VAR_0B00\256
	XPAL P1

	LD KEYPRESS_1(2)
	XAE
	LD -128(P1)
	XPAL P1					;Set P1 to = 0x0B Card Number 

	LD COUNT(2)
	XAE
	LD -128(P1)				;Load Card at 0x0B?? 
	JP COPY_CARD			;Check for hidden cards, hidden cards are negative
	JMP COPY_CARDS_RETURN	;No need to copy hidden cards
	
COPY_CARD:
	ST CARD(2)
	
	LDI VAR_SWAP\256
	XPAL P1	
	
	ILD @0(P1)			;Increment Number of cards in column
	ST MOVE_COUNT(2)
	XAE		
	LD CARD(2)
	ST -128(P1)	
	
	ANI 0x0F
	ST CARD1_VAL(2)

	DLD COUNT(2)
	JNZ LOOP6

COPY_CARDS_RETURN:

	LD MOVE_COUNT(2)
	ST COUNT(2)
	RET P3

;=====================================================================
ADD_CARD
	LDI VAR_0B00/256
	XPAH P1
	LDI VAR_0B00\256
	XPAL P1

	LD COL(2)
	XAE
	LD -128(P1)
	XPAL P1				;Set P1 to = 0x0B Card Number 
	
	ILD @0(P1)			;Increment Number of cards in column
	XAE	
	
	LD FOUNDATION2(2)
	JZ STORE_CARD		;Check if foundation, if so store card at plus 1
	XAE
	
STORE_CARD:
	LD COL(2)
	XRI 0x08
	JNZ STORE_CARD2
	LD CARD(2)
	ORI 0x80			;Hide cards in Stack
	ST CARD(2)
	
STORE_CARD2:
	LD CARD(2)
	ST -128(P1)			;Store Card at 0x0B00 

ADD_CARD_RETURN:
	RET P3
	
;======================================================================
GET_CARD_DETAILS: 
	LDI  0x20					; space character
	ST C_N_ASC(2)
	ST C_S_ASC(2)
	
	LD CARD(2)
	JZ GET_CARD_DETAILS_RETURN	;No need to get card details
	
	ANI 0x0F
	ST C_NUM(2)					;Card Number
	
	LDI		VAR_0880/256		;Card Asc Values held at 0880
	XPAH	P1
	LDI		VAR_0880\256
	XPAL	P1
	
	LD C_NUM(2)
	XAE
	LD -128(P1)
	ST C_N_ASC(2)
	

	LD CARD(2)
	ANI 0x30
	RR
	RR
	RR
	RR
	ST C_SUIT(2)				;Card Suit
	
	LDI		VAR_088E/256		;Card Suit Asc Values
	XPAH	P1
	LDI		VAR_088E\256
	XPAL	P1
	
	LD C_SUIT(2)
	XAE
	LD -128(P1)
	ST C_S_ASC(2)
	
	LD CARD(2)
	ANI 0x80					;Check if card is hidden
	ST C_HIDE(2)
	JZ GET_CARD_DETAILS_RETURN
	
	LDI 0x24				;Card Hide Charater, normally $
	ST C_N_ASC(2)
	ST C_S_ASC(2)

GET_CARD_DETAILS_RETURN:	
	RET P3	
;======================================================================
;======================================================================
;======================================================================
;======================================================================
	.OR PROG3
	
CALCULATE_CARDS_TO_MOVE:
	
	LD MOVE_COUNT(2)
	ST COUNT(2)
	
LOOP7:	
	LDI VAR_SWAP/256			;Swap area currently 0x0BBC
	XPAH P1
	LDI VAR_SWAP\256
	XPAL P1
	
	LD COUNT(2)
	XAE	
	LD -128(P1)			;Load Card at 0x0B??  
	ST CARD(2)
	
	ANI 0x0F
	ST CARD1_VAL(2)
	LD CARD(2)
	ANI 0x10			;5th Bit Set for black card
	ST CARD1_BLACK(2)

CHECK_VALUE2:
	LD CARD1_VAL(2)
	ADI 0x01
	XOR CARD2_VAL(2)
	JNZ CHECK_NEXT_CARD
	
CHECK_COLOUR2:	
	LD CARD1_BLACK(2)
	XOR CARD2_BLACK(2)
	JZ CHECK_NEXT_CARD	
	LDI 0x12
	ST VALID(2)						;Valid Move
	
	JMP CALCULATE_CARDS_TO_MOVE_RETURN

CHECK_NEXT_CARD:
	DLD COUNT(2)
	JNZ LOOP7

CALCULATE_CARDS_TO_MOVE_RETURN:
	RET P3

;======================================================================
;======================================================================


	
EXEC_ADR:	
	.NO 0xFFFE
	.DB ENTRY/256
	.DB ENTRY\256

