	.CR	SCMP
	.TF	Invaders.HEX,INT
;	.TF Invaders.BIN,bin
	.LF	Invaders.LST
	
; *****************************************************************************
; MK14 Space Invaders game
; Rev 1.0
; Written by Ian Reynolds October 2022 for the SBASM 8060 assembler
; 
; Requires continuous memory from 0200 to 07FF and base RAM at 0xF00
; INS8154 setup is specific to the ZEDEX8Y MK14 VDU module, so may need adjustment for operation with 
; the original SoC MK14 VDU card
; For correct operation the VDU TOPPAGE signal needs to be connected to the PS1, to use 2 pages of video RAM
;
; You have 5 lives
; When you clear all invaders from the screen a new set of invaders appear
; Hitting an invader gets you 1 point, up to a maximum 99 points
; The invaders are rotated across the screen. After 14 rotations the invaders drop down a row
;
; Keys: 1 to move shooter left
;       2 to shoot a bullet
;       3 to move shooter right
;       GO to restart game once all lives are used
;       ABORT to exit to monitor at any time
;
; All characters on screen are defined by constants, so easy to customise
;
; Visit the UK Vintage Radio Forums, Vintage Computers, for updates
;
; https://www.vintage-radio.net/     My username is Realtime
; *****************************************************************************
	
;Game Constants
DISPL        .EQ 0x0200       ; Start of VDU frame store
PROG         .EQ 0x0400       ; Start of program memory
VAR          .EQ 0x0F20       ; Place variables in base RAM
INS8154      .EQ 0x0800       ; MK14 I/O chip base address
Char_Border  .EQ 0x2D         ; '-'
Char_Space   .EQ 0x20         ; ' '
Char_InvL    .EQ 0x1C         ; '\'
Char_InvR    .EQ 0x2F         ; '/'
Char_Shooter .EQ 0x01         ; 'A'
Char_Bullet  .EQ 0x3A         ; ':'
Char_Bomb    .EQ 0x2A         ; '*'
Char_Block   .EQ 0x23         ; '#'
Shoot_Y      .EQ DISPL/256+1  ; Lower page of video RAM
Shoot_X_pos  .EQ 0xD0         ; 3rd to last row
Score_line   .EQ 0xF0         ; Last row
Title_line   .EQ 0x11         ; Top row above border
Block_L      .EQ 0x61         ; Low byte of position of Blocks
Block_H      .EQ DISPL/256+1  ; High byte of position of Blocks
Delay_time   .EQ 0x00         ; Set the speed of the game. 0x00 to 0xFF (slowest to fastest)

; Game Variables
Shoot_X      .EQ 0x00         ; x-address of shooter (0x0-0xF)
Bullet_X     .EQ 0x01         ; x-position of the bullet
Bullet_Y     .EQ 0x02         ; y-position of the bullet
Bullet_ON    .EQ 0x03         ; non-zero if bullet is active
Bomb_X       .EQ 0x04         ; x-position of bomb
Bomb_Y       .EQ 0x05         ; y-position of bomb
Bomb_ON      .EQ 0x06         ; non-zero if bomb is active
Game_over    .EQ 0x07         ; non-zero if game over
Lives        .EQ 0x08         ; number of shooter lives left
Points       .EQ 0x09         ; Points counter (BCD up to 99)
Rot_loops    .EQ 0x0A         ; Count down. When zero the invaders are rotated left
Drop_row     .EQ 0x0B         ; Count down. When zero the invaders can be dropped down one row
Inv_row1H    .EQ 0x0C         ; Address of first row of invaders
Inv_row1L    .EQ 0x0D         ; Address of first row of invaders
Inv_row2H    .EQ 0x0E         ; Address of second row of invaders
Inv_row2L    .EQ 0x0F         ; Address of second row of invaders
Inv_row3H    .EQ 0x10         ; Address of second row of invaders
Inv_row3L    .EQ 0x11         ; Address of second row of invaders
Count1       .EQ 0x12         ; General purpose loop counter
Count2       .EQ 0x13         ; General purpose loop counter
Det_Inv      .EQ 0x14         ; Non-zero when invaders detected on screen
Ret_H        .EQ 0x15         ; High byte of return-to-monitor address (ABORT)
Ret_L        .EQ 0x16         ; Low byte of return-to-monitor address (ABORT)

; ****************************************************************************

   .OR	PROG
	
ENTER:	

	LDI VAR/256
	XPAH	P2
	LDI	VAR\256
	XPAL	P2

	XPAH P3      ; Store return to monitor address
	ST Ret_H(P2)
    XPAL P3
	ST Ret_L(P2)
	
; Set up INS8154 
; The following is for Realtime's MK14 VDU, using Port B for the control byte
; Other VDU's may require different set up byte

	LDI	INS8154/256 ; Base address of I/O device
	XPAH	P3
	LDI	INS8154\256
	XPAL	P3
	LDI	0xFF        ; Set Port B as all outputs
    ST 0x23(P3)     ; Port B outut definition register
    LDI 0x22        ; Set VDU control bits
	ST 0x21(P3)     ; Port B write address

;   Port B bit 7 = PS3 - set to '0'      \
;   Port B bit 6 = PS1 - set to '0'       \  Sets the video RAM address to 0x0200
;   Port B bit 5 = PS2 - set to '1'       /  However, note that PS1 must not be physically connected
;   Port B bit 4 = PS4 - set to '0'      /   to the VDU card as this line is controlled by the TOPPAGE signal
;   Port B bit 3 = VDUOFF               - set to '0' for VDU on
;   Port B bit 2 = Graphics/nCharacters - set to '0' for character mode
;   Port B bit 1 = REVPAGES             - set to '0' for 0x200 at top of the screen (0x300 at bottom)
;   Port B bit 0 = INVERT               - set to '0' for white on black video

;   LDI	0x00		; or lower FLAG2 for other card designs
;   CAS		

START:

; These variables get set only for first round of a game	
	LDI 0x00
	ST Points(P2)     ; Zero points
    ST Game_over(P2)  ; Game not over
	LDI	0x05
    ST Lives(P2)      ; Five shooter lives
	LDI 0x09
	ST Shoot_X(P2)    ; Place shooter at middle of screen
    LDI 0x40        
	ST Inv_row1L(P2)  ; Set display position for 1st row of invaders
	LDI	0x60
	ST Inv_row2L(P2)  ; Set display position for 2nd row of invaders
    LDI 0x80
	ST Inv_row3L(P2)  ; Set display position for 3rd row of invaders
    LDI DISPL/256
	ST Inv_row1H(P2)  ; Place all invaders in top half of screen
	ST Inv_row2H(P2)
	ST Inv_row3H(P2)
	
INVADE:
;================================================
; Create the start-up screen
;================================================
; Fill display with spaces	
    LDI	DISPL/256	; lower display memory page high byte
	XPAH	P1
	LDI	DISPL\256  ; lower display memory page low byte 
    XPAL	P1      ; P1 now points to start of display
SC1:
	LDI	Char_Space    ; space character to clear screen
	ST	@1(P1)        ; store and auto increment by 1
	XPAH	P1
	XRI	DISPL/256+2   ; XOR for comparison
	JZ	SC2            ; Is P1_H equal to 04? if yes then finished clearing RAM 
	XRI	DISPL/256+2   ; Restore P1_H
	XPAH	P1
	JMP	SC1	
	
; Fill the third line (using P1) of display with '-'
; Fill the 2nd to last line (using P2) of display with '-'
SC2:
    LDI	DISPL/256
	XPAH	P1
	LDI	0x20  
    XPAL	P1      ; P1 contains start address of 2nd display row
    LDI	DISPL/256+1
	XPAH	P3
	LDI	Shoot_X_pos+0x10 
    XPAL	P3      ; P2 contains start address of 2nd to last display row
SC3:	LDI Char_Border ; upper and lower boarder character
	ST	@1(P1)
	ST  @1(P3)
	XPAL	P1
	XRI	0x30        ; XOR for comparison of 16 characters placed (P1_L started at 0x20)
	JZ	SC4          ; Is P1_L equal to 0x10? if yes then finished border rows 
	XRI	0x30        ; Restore P1_L
	XPAL	P1
	JMP	SC3	
	
; Draw the protection blocks
SC4:
    LDI	Block_H       ; Top Of Blocks
    XPAH	P1
	LDI	Block_L	
    XPAL	P1    
	LDI 0xFD            ;  -3 = 3 rows of block
SC5: 
    XPAH    P3
	LDI 0xFD
SC6:	XPAL    P3          ; -3 = 3 blocks per row
	LDI	Char_Block	    ; Block #
	ST	@1(P1)	        ; 3 characters wide
	ST	@1(P1)
	ST	@1(P1)
	LD	@2(P1)	        ; 2 spaces
    CCL                 ; Clear the carry flag
	XPAL    P3
	ADI 0x01
	JNZ SC6
	LD	@0x11(P1)	    ; jump a display line
    CCL                 ; Clear the carry flag
    XPAH	P3
	ADI 0x01
	JNZ SC5

; Draw the Invaders
	LD	Inv_row1H(P2)   ; Top Of invaders
    XPAH	P1
	LD	Inv_row1L(P2)
    XPAL	P1          
    LDI 0x03            ; 3 rows of invaders
    ST Count1(P2)
SC7:
	LDI Invader_Line/256 ; Get start address of invader text block
	XPAH P3
	LDI Invader_Line\256
	XPAL P3
SC8:
    LD @1(P3)            ; copy it to screen
	JZ SC9
	ST @1(P1)
	JMP SC8
SC9:
    LD @17(P1)           ; Move screen position on 23 bytes
	DLD Count1(P2)
	JNZ SC7              ; repeat
	
; Place the shooter
	LDI	Shoot_X_pos
	OR Shoot_X(P2)       ; move shooter to middle of line
    XPAL	P1
	LDI	Shoot_Y
    XPAH	P1  
	LDI	Char_Shooter
	ST	(P1)	         ; display shooter

; Output score line text
    LDI Score_text/256   ; Get start address of score text block
	XPAH P3
	LDI Score_text\256
	XPAL P3
	LDI DISPL/256+1
	XPAH P1
	LDI Score_line
	XPAL P1
SC10:
	LD @1(P3)            ; copy it to screen
	JZ SC11
	ST @1(P1)
	JMP SC10
	
; Output Title text
SC11:
    LDI Title_text/256   ; Get start address of Title text block
	XPAH P3
	LDI Title_text\256
	XPAL P3
	LDI DISPL/256
	XPAH P1
	LDI Title_line
	XPAL P1
SC12:
	LD @1(P3)            ; copy it to screen
	JZ SC13
	ST @1(P1)
	JMP SC12	

;================================================
; Initialise variables for each round of the game
;================================================
SC13:
	LDI	0x00
	ST Bullet_ON(P2)  ; Bullet not active
	ST Bomb_ON(P2)    ; Bomb not active
	LDI Shoot_Y       ; Initial offset for bullet firing
    ST Bullet_Y(P2)
	LDI 0x0E
	ST Det_Inv(P2)    ; Reset invaders on screen flag (any non zero value)
	ST Rot_loops(P2)  ; Number of game loops before invaders are rotated
	ST Drop_row(P2)   ; Number of rotates before invaders drop down a row
	LDI 0xC9
	ST Bullet_X(P2)   ; Initial X position of bullet

; Bomb_X, Bomb_Y, Rot_bytes, Count1, Count2 get initialised elsewhere on first use

;================================================
; MAIN GAME LOOP
;================================================
; Fire bullet upwards	
;================================================
FB0:   
	LD Bullet_ON(P2)
	JZ FB_EXIT
	LD Bullet_Y(P2)    ; get display position of Bullet
	XPAH P1
	LD Bullet_X(P2)
	XPAL P1	
	LD (P1)            ; get character from display RAM at bullet position (before bullet gets displayed)
	XRI Char_Space     ; is it a space (background)?
	JNZ FB1
    LDI Char_Bullet    ; Place bullet character on screen
	ST (P1)
    LDI Char_Space
	ST 0x10(P1)        ; replace previous position with a space
	LD Bullet_X(P2)    ; Get position of bullet
	XPAL P3   
    LD Bullet_Y(P2)
	XPAH P3
	LD @-0x10(P3)      ; Move position to the next row above
	XPAH P3            ; and store
	ST Bullet_Y(P2)
    XPAL P3
	ST Bullet_X(P2)   
	JMP FB_EXIT
FB1:	
	LD (P1)            ; get character from display RAM at bullet position
	XRI Char_Block     ; is it part of the defences?
	JZ FB_END
	LD (P1)            ; get character from display RAM at bullet position
	XRI Char_InvL      ; is it an invader?
	JNZ FB2
    LDI Char_Space
	ST 0x01(P1)        ; clear one character to right of bullet position
	JMP FB22
FB2:
	LD (P1)            ; get character from display RAM at bullet position
	XRI Char_InvR      ; is it an invader?
	JNZ FB3
    LDI Char_Space
	ST -1(P1)          ; clear one character to left of bullet position
FB22:
	LD Points(P2)      ; Add 1 to points
	XRI 0x99           ; unless it's already reached 99 (BCD)
	JZ FB_END
	LD Points(P2)
	CCL
    DAI	0x01           ; Decimal add - i.e. BCD counter  
	ST Points(P2)
	JMP FB_END
FB3:
    ; Uncomment next 3 lines for bullet to get destroyed by collision with a bomb
	 LD (P1)          ; get character from display RAM at bullet position
	 XRI Char_Bomb    ; is it a bomb?
	 JZ FB_END
FB4:
	LD (P1) 
	XRI Char_Border    ; Has it reached the top of screen
	JNZ FB_EXIT
	LDI Char_Space
	ST 0x10(P1)        ; clear previous bullet position
	JMP BULLET_OFF
FB_END:
	LDI Char_Space
	ST (P1)            ; clear screen at bullet position
	ST 0x10(P1)        ; replace previous position with a space
BULLET_OFF:
    LDI 0x00          
	ST Bullet_ON(P2)   ; Set bullet to inactive		
	LDI 0xC7
    ST Bullet_X(P2)    ; Set initial offset for bullet firing
	LDI Shoot_Y
    ST Bullet_Y(P2)
FB_EXIT:
	
;================================================
; Move the shooter
;================================================  
    LDI Shoot_Y        ; Derrmine where Shooter shold be
    XPAH P1
	LD Shoot_X(P2)
    ORI Shoot_X_pos
    XPAL P1
    LDI Char_Shooter
    ST (P1)            ; Place the shooter
	LDI Char_Space
	ST -1(P1)	       ; clear to left of shooter to overwrite old position
	LD Shoot_X(P2)
	XRI 0x0F
	JZ DB0             ; If shooter is not at far right then clear to right to overwrite old position
	LDI Char_Space
	ST 1(P1)
	
;================================================
; Drop Bomb
;================================================   
DB0:
	LD Bomb_ON(P2)
	JZ DB_EXIT
	LD Bomb_Y(P2)      ; get display position of Bomb
	XPAH P1
	LD Bomb_X(P2)
	XPAL P1	
	LD (P1)            ; get character from display RAM at bomb position (before bomb gets displayed)
	XRI Char_Space     ; is it a space (background)?
	JNZ DB1
    LDI Char_Bomb
	ST (P1)            ; Place Bomb on screen
    LDI Char_Space
	ST -0x10(P1)       ; Clear previous position
	LD Bomb_X(P2)
	XPAL P3   
    LD Bomb_Y(P2)
	XPAH P3
	LD @0x10(P3)      ; Move position of Bomb to the next row
	XPAH P3
	ST Bomb_Y(P2)
    XPAL P3
	ST Bomb_X(P2)   
	JMP DB_EXIT
DB1:	
	LD (P1)            ; get character from display RAM at Bomb position
	XRI Char_Block     ; is it part of the defences?
	JZ DB_END
DB3:
	LD (P1)            ; get character from display RAM at Bomb position
	XRI Char_Shooter   ; is it the shooter?
	JNZ DB4
	DLD Lives(P2)      ; Decrement number of Lives
	JNZ DB_END         ; If lives=0 then game over
    LDI 0x01
	ST Game_over(P2)   ; Set game over
	JMP BOMB_OFF    
DB4:	
    ; Uncomment next 3 lines for bomb to get destroyed by collision with a bullet
	 LD (P1)            ; get character from display RAM at Bomb position
	 XRI Char_Bullet    ; is it a bullet?
	 JZ DB_END
DB5:	
	LD (P1)            
	XRI Char_Border    ; has the bomb reached the bottom of screen?
	JNZ DB_EXIT
	LDI Char_Space
	ST -0x10(P1)       ; Clear previous position
	JMP BOMB_OFF
DB_END:
	LDI Char_Space
	ST (P1)            ; Clear Bomb from screen
	ST -0x10(P1) 
BOMB_OFF:
    LDI 0x00 
	ST Bomb_ON(P2)     ; Set Bomb to inactive		

DB_EXIT:

;================================================
; Display Lives and Points
;================================================
   LDI Shoot_Y     ; Determine position of score line on display
   XPAH P1
   LDI Score_line+0x06
   XPAL P1
   LD Lives(P2)    ; Get Lives
   ADI 0x30        ; Convert to number character
   ST @0x09(P1)    ; Display Lives and move P1 to Points position
   LD Points(P2)   ; Get points (BCD counter)
   ANI 0x0F        ; Mask off lower nibble
   ADI 0x30        ; Convert to number character
   ST (P1)         ; Display number
   LD Points(P2)   ; Reload points
   ANI 0xF0        ; Mask off upper nibble
   SR              ; Shift right 4 times
   SR
   SR
   SR
   ADI 0x30        ; Convert to number character
   ST -1(P1)       ; Display number 
   
;================================================
; Scan upwards for an invader above shooter X position and enable drop bomb
;================================================
	LD Bomb_ON(P2)     ; if Bomb already dispatched then exit
	JNZ SU_EXIT
	LD Shoot_X(P2)     ; get position of shooter
	XPAL P1
	LDI Shoot_Y
	XPAH P1
SU0:
	LD (P1)            ; get character from display RAM at scan position
	XRI Char_InvL      ; is it an invader?
	JZ SU1
	LD (P1)            ; get character from display RAM at scan position
	XRI Char_InvR      ; is it an invader
    JZ  SU1
	LD (P1)            ; get character from display RAM at scan position
	XRI Char_Border    ; has the scan reached the top of the display? If yes, exit as no invader found above the shooter
    JZ SU_EXIT
	LD @-0x10(P1)      ; decrement to the next row above and repeat  
	JMP SU0
SU1:	
	LD @0x20(P1)       ; move down 2 rows
	XPAH P1            ; Align bomb release position with detected invader
	ST Bomb_Y(P2)
	XPAL P1
	ST Bomb_X(P2)
	LDI 0x01
	ST Bomb_ON(P2)     ; Enable bomb drop
SU_EXIT:	

;================================================
; Check if game is over, otherwise rotate each row of invaders
;================================================
   LD Game_over(P2)
   JNZ RT1            ; IF not zero then game over so don't move the invaders
   DLD Rot_loops(P2)
   JZ RT2              ; IF rotation loop counter not zero then don't move the invaders
RT1:
   JS P3,RT10          ; Jump Subroutine makes a forward jump >7F bytes. There is no return from RT10
RT2:
   LD Bullet_ON(P2)  ; If the bullet is enabled then blank it while rotating
   JZ RT3
   LD Bullet_Y(P2)
   XPAH P1
   LD Bullet_X(P2)
   XPAL P1
   LDI Char_Space
   ST 0x10(P1)  
RT3:   
   LD Bomb_ON(P2)  ; If the Bomb is enabled then blank it while rotating
   JZ RT4
   LD Bomb_Y(P2)
   XPAH P1
   LD Bomb_X(P2)
   XPAL P1
   LDI Char_Space
   ST -0x10(P1) 
RT4:
   LDI 0x0E 
   ST Rot_loops(P2)        ; Re-initialise the rotation counter
   
; check if any invaders left on screen
   LDI 0x00                ; Reset Invaders detected flag (zero means none detected)
   ST Det_Inv(P2)
   LDI 0x60                ; The complete set of invaders spans 0x60 locations on the display
   ST Count1(P2)           ; initialise counter
   LD Inv_row3H(P2)
   XPAH P1
   LD Inv_row3L(P2)
   ORI 0x0F                ; P1 now points to last position in last row of invaders
   XPAL P1
RT5:
   LD (P1)                 ; Determine if any of the 0x60 locations contain an invader character   
   XRI Char_InvL
   JZ RT6
   LD @-1(P1)
   XRI Char_InvR
   JNZ RT7
RT6:
   LDI 0x01                ; Invaders detected
   ST Det_Inv(P2)          ; The result in Det_Inv will be 0x01 if any invaders are on screen 
RT7:
   DLD count1(P2)
   JNZ RT5
; Rotate all rows
   LD Inv_row1L(P2)        ; Each row of invaders has it's own pointer register defining where it is on screen
   XPAL P1
   LD Inv_row1H(P2)
   XPAH P1
   JS P3,SFT_L             ; Rotate row 1
   LD Inv_row2L(P2)
   XPAL P1
   LD Inv_row2H(P2)
   XPAH P1
   JS P3,SFT_L             ; Rotate row 2
   LD Inv_row3L(P2)
   XPAL P1
   LD Inv_row3H(P2)
   XPAH P1
   JS P3,SFT_L             ; Rotate row 3
   
;================================================
; Move invaders down one row
;================================================  
   DLD Drop_row(P2)        ; Decrment loop counter
   JNZ RT10                  ; If count is zero then drop invaders down a row, else exit 
   LD Inv_row1H(P2)        ; Check if invaders have reached low threshold 
   XRI DISPL/256
   JNZ RT8
   LD Inv_row1L(P2)
   ANI 0xE0
   XRI 0xE0
   JNZ RT8                 ; Jump to drop function
   JMP RT10                  ; If Invader top row is at 0x02Ex then don't drop down any more
RT8:
   LDI 0x0B
   ST Drop_row(P2)         ; Reset the drop loop counter
   LDI 0x60                ; The complete set of invaders spans 0x60 locations on the display
   ST Count1(P2)           ; initialise counter
   LD Inv_row3H(P2)
   XPAH P1
   LD Inv_row3L(P2)
   ORI 0x0F                ; P1 points to last position in last row of invaders
   XPAL P1
RT9:
   LD (P1)                 ; Move display block down one row (0x10 locations)
   ST 0x10(P1)
   LD @-1(P1)
   DLD count1(P2)
   JNZ RT9
   
   LD Inv_row1H(P2)        ; Increment row 1 pointer by 0x10 locations
   XPAH P3
   LD Inv_row1L(P2)
   XPAL P3
   LD @0x10(P3)
   XPAL P3
   ST Inv_row1L(P2)
   XPAH P3
   ST Inv_row1H(P2)   
   
   LD Inv_row2H(P2)        ; Increment row 2 pointer by 0x10 locations
   XPAH P3
   LD Inv_row2L(P2)
   XPAL P3
   LD @0x10(P3)
   XPAL P3
   ST Inv_row2L(P2)
   XPAH P3
   ST Inv_row2H(P2)   
 
   LD Inv_row3H(P2)        ; Increment row 3 pointer by 0x10 locations
   XPAH P3
   LD Inv_row3L(P2)
   XPAL P3
   LD @0x10(P3)
   XPAL P3
   ST Inv_row3L(P2)
   XPAH P3
   ST Inv_row3H(P2)
   
;================================================
; Jump to reload start screen and continue with game if all invaders have been cleared
;================================================  
RT10:
   LD Det_Inv(P2)  ; Check if any invaders detected on screen (non zero)
   JNZ G_OVER
   JS P3,INVADE    ; JS used as a long jump. No return from INVADE

;================================================
; Check game over flag
;================================================ 
G_OVER:
   LD Game_over(P2)          ; If flag set then game is over (Lives=0)
   JZ KBD                    ; Otherwise scan the keyboard
   LDI 0x00                  ; Set Bullet and Bomb off
   ST Bullet_ON(P2)
   ST Bomb_ON(P2)
   
; Output game over text
GO0:
    LDI End_text/256         ; Get start address of Game Over text
	XPAH P3         
	LDI End_text\256
	XPAL P3         
	LDI DISPL/256   
	XPAH P1         
	LDI 0xE4        
	XPAL P1         
GO1:                
	LD @1(P3)                ; copy it to screen
	JZ KBD
	ST @1(P1)
	JMP GO1 

;================================================
; scan keyboard for 1,2,3, GO, ABORT
;================================================
KBD:
	LDI 0x0D			  ; point to MK14 display/keyboard
	XPAH P3   
	LDI 0x00
	XPAL P3
    LDI 0x00
	ST (P3)               ; Set all display segments to off	
	LD Game_over(P2)      ; If Game over flag is set then only test GO and ABORT keys
	JNZ TEST_GO	
TEST_1:                   ; Move shooter left
    LD 1(P3)              ; read keypad 0x0D01 (Key 1)
	ORI 0x0F              ; Mask top 4 bits
	XRI 0x7F              ; Result will be zero if key pressed
	JNZ TEST_2
	LD Shoot_X(P2)        ; get current shooter position
	JZ TEST_2             ; If it's already zero then can't move left
	DLD Shoot_X(P2)
TEST_2:                   ; Shoot bullet
	LD 2(P3)              ; read keypad 0x0D02 (Key 2)
	ORI 0x0F              ; Mask top 4 bits
	XRI 0x7F              ; Result will be zero if key pressed
	JNZ TEST_3
	LD Bullet_ON(P2)      ; if bullet already in action then ignore key press
	JNZ TEST_3
	LDI 0x01
	ST Bullet_ON(P2)      ; set bullet active 
	LD Bullet_X(P2)       ; Set bullet release position to Shooter X position
    ANI 0xF0              ; Keep top 4 bits that define the row
	XOR Shoot_X(P2)       ; add current shooter X position
	ST Bullet_X(P2)       ; update position
TEST_3:                   ; Move shooter right
    LD 3(P3)              ; read keypad 0x0D03 (Key 3)
	ORI 0x0F              ; Mask top 4 bits
	XRI 0x7F              ; Result will be zero if key pressed
    JNZ TEST_ABORT
	LD Shoot_X(P2)        ; get current shooter position
    XRI 0x0F
	JZ TEST_ABORT         ; If it's already 15 then can't move right
	ILD Shoot_X(P2)
TEST_GO:                  ; New Game
	LD 2(P3)              ; read keypad 0x0D02 (Key GO)
	ORI 0x0F              ; Mask top 4 bits
	XRI 0xDF              ; Result will be zero if key pressed
    JNZ TEST_ABORT	
	JS P3,START           ; Restart the game (no return from JS will occur)
TEST_ABORT:               ; Abort to Monitor *** commented out to free up some space ***
	LD 4(P3)              ; read keypad 0x0D04 (Key ABORT)
	ORI 0x0F              ; Mask top 4 bits
	XRI 0xDF              ; Result will be zero if key pressed
    JNZ DLY
    LD Ret_H(P2)          ; Reinstate the monitor entry point
    XPAH P3
    LD Ret_L(P2)
    XPAL P3
    XPPC P3               ; return to the monitor
DLY:	
	LDI Delay_time        ; Set the speed of the game
	DLY 0x90              ; INS8060 hardware delay command
	
	JS P3,FB0            ; Jump to game main loop (no return from JS will occur)

;================================================
; Subroutine to shift left a row of invaders, twice
;================================================
SFT_L:
    LDI 0x02             ; Do it twice to avoid half an invader being displayed
	ST Count1(P2)	
SL1:
	LDI 0x0F             ; 15 lcoations rotated left ...
	ST Count2(P2)
	LD (P1)
	XAE                  ; with the 16th location temporarily stored in the Extension register
SL2:	
	LD 1(P1)             ; Do the rotate
	ST @1(P1)
    DLD Count2(P2)
	JNZ SL2
	XAE                  ; place 16th postion
	ST (P1)
	LD @-0x0F(P1)
    DLD Count1(P2)
	JNZ SL1
	RET P3

;================================================
; Lines of Text for writing to display. EOL is 0x00
;================================================
Invader_Line .DB Char_InvL,Char_InvR,Char_Space,Char_Space                                    ; Invader set up pattern
	         .DB Char_InvL,Char_InvR,Char_Space,Char_Space 
			 .DB Char_InvL,Char_InvR,Char_Space,Char_Space
			 .DB Char_InvL,Char_InvR,Char_Space,0x00
Title_text   .DB 0x0D,0x0B,0x31,0x34,0x20,0x20,0x09,0x0E,0x16,0x01,0x04,0x05,0x12,0x13,0x00   ; MK14  INVADERS
Score_text   .DB 0x0C,0X09,0X16,0X05,0X13,0X3A,0x20,0x20,0X13,0X03,0X0F,0X12,0X05,0x3A,0x00   ; LIVES:  SCORE:
End_text     .DB 0x07,0x01,0x0D,0x05,0x20,0x0F,0x16,0x05,0x12,0x20,0x20,0x20,0x20,0x20        ; GAME OVER
Go_text      .DB 0x20,0x20,0x10,0x12,0x05,0x13,0x13,0x20,0x07,0x0F,0x20,0x00                  ; PRESS GO

	