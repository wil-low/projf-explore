; *****************************************************************************
;
;                          SEGTRIS by Paul Robson 1998
;                          ===========================
;
;       The idea behind this game is that segment scroll on the screen
;       from left to right. Segments A,B,C,D,E and F are used. Keys 1 and
;       3 rotate the segments left and right, and they have to collapse
;       into an '0' formation.
;
;       It's basically a right to left tetris for a 7 segment display
;       Requires extended memory to work, at least another 1/2k somewhere
;
;       Runs from start of extended memory. On exit, score can be displayed
;       by pressing MEM, then the program can be re-run using MEM/GO.
;
;       The starting speed can be changed by altering the StartSpeed
;       byte at 0F14h
;
; *****************************************************************************

		.CR scmp
		.LF segtris.lst
		.TF segtris.hex,INT

MoreRAM         .eq    0B00h           ; 0A00 = I/O Chip,0B00 = Extend RAM
         
SegArray        .eq    0               ; SegArray contains the current
                                        ; game status, from F00 (right) to
                                        ; F07/8 left. Can't really be moved.

Speed           .eq    09h
DelayCount      .eq    0Ah             ; Number of display loops to next shift
Posn            .eq    0Bh             ; Position of piece in display
Shape           .eq    0Ch             ; Shape of piece
Collapse        .eq    0Dh             ; Set to '1' if collapse required ?
Pattern         .eq    0Eh             ; Pattern pointer for random numbers
Kb1             .eq    0Fh             ; Left and right keys
Kb3             .eq    10h
Temp            .eq    11h             ; workspace
Score           .eq    12h             ; Score

        .or    0F14h

; *****************************************************************************
;
;       Start Speed and Table of Shapes. These correspond to bit patterns
;       in the LEDs. A random number is ANDed with STMask to give an offset
;       into the table to get one of these patterns. STMask must be an
;       2^x-1 e.g. 3,7 or 15 in practice.
;
; *****************************************************************************

StartSpeed:     .db     0F0h

STMask  .eq    15                      ; shape table mask

ShapeTable:                             ; shapes
        .db     01h,02h,04h,08h,10h,20h ; single bar (6 off)
        .db     03h,06h,0Ch,18h,30h     ; double bar (5 off)
        .db     0Eh,38h                 ; triple bar (2 off)
        .db     1Ah                     ; spaced (1 off)
        .db     01h,04h,20h             ; more single bars (3 off)

; *****************************************************************************
;
;       Main display loop. Comes here every 'drop', and scans the keyboard
;       looking for rotation presses, while displaying the game.
;
; *****************************************************************************
Display:
        ld      Speed(1)                ; reset the delay loop count
        sr
        sr
        ani     3Fh
        st      DelayCount(1)
Display2:

        ldi     0Dh                     ; P2 = 0D00h (the display)
        xpah    2                       ; P1 already = 0F00h (the segment data)
        ldi     00h
        xpal    2
        ldi     8                       ; refresh the game display, this
        xae                             ; displays 9 digits.
_Disp1: ld      80h(1)                  ; refresh display
        ori     80h                     ; light DP for alignment
        st      80h(2)                  ; Segarray MUST be at 0F00h here
        dly     02
        ldi     0FFh                    ; decrement E
        ccl
        ade
        xae
        lde                             ; go back if >= 0
        jp      _Disp1                  ; to draw the whole display

        js      3,Keyboard      		; call the keyboard scanning routine

        dld     DelayCount(1)           ; have we done a full screen
        jnz     Display2                ; go back around again
; *****************************************************************************
;
;                     now drop the current piece in by 1
;
; *****************************************************************************
        ld      Posn(1)                 ; Make P2 point to the piece position
        xpal    2
        ldi     0Fh
        xpah    2

        ld      1(2)                    ; look at the next position
        xri     255                     ; if it is $FF it is at the bottom
        jz      EndPiece                ; of the display (aka left !)

        ld      Shape(1)                ; if any of the pieces don't fit
        and     1(2)                    ; e.g. we can't drop it because
        jnz     EndPiece                ; a segment in both is on.. new piece

        ld      Shape(1)                ; clear the old bits out
        xor     0(2)
        st      0(2)

        ld      Shape(1)                ; draw it in its new place
        xor     1(2)
        st      1(2)

        xri     3Fh                     ; does it make a solid
        jz      EndPiece                ; we can't drop any more if so..

        ild     Posn(1)                 ; increment the position, move right
        jmp     Display                 ; go back and try again
; *****************************************************************************
;
;                  test for potential display 'collapse'
;
; *****************************************************************************
EndPiece:
        ldi     0                       ; clear collapse flag
        st      Collapse(1)
        ldi     0Fh                     ; make P2 point to the shape buffer
        xpah    2
        ldi     SegArray+08h
_EndLoop:                               ; saves a bit of coding...
        xpal    2
        ld      0(2)                    ; look at the pattern.
        xri     3Fh                     ; if it is "filled"
        jnz     _TryNext                ; we can remove it.
        ldi     0                       ; we can delete this one.
        st      0(2)
        ild     Score(1)                ; increment the score by 1
        dld     Speed(1)                ; decrement the speed
        ldi     1                       ; set the collapse flag
        st      Collapse(1)
_TryNext:
        ld      @-1(2)                  ; decrement the pointer
        xpal    2                       ; if it is not the end you can
        jnz     _EndLoop                ; try again. This requires SegArray
                                        ; to be at 0F00h

        ld      Collapse(1)             ; do we need to collapse it ?
        jz      NewPiece
        js      3,CollapseCode	        ; Call the collapse routine
        jmp     NewPiece
; *****************************************************************************
;
;                    generate a new piece for the display
;
; *****************************************************************************
NewPiece:
        ld      0(1)                    ; is the game over - there is no
        jnz     GameOver                ; space for a new piece ?

_BadPattern:
        ild     Pattern(1)              ; get the next pattern
        xpal    2                       ; a *very* dodgy psuedo random
        ldi     0                       ; routine
        xpah    2
        ld      0(2)
        add     3(2)
        xor     7(2)
        ani     STMask                  ; make it in the range 0..x
        adi     ShapeTable & 255        ; offset into shape table
        xae
        ld      80h(1)                  ; get the shape
        st      Shape(1)
        st      SegArray+0(1)           ; put shape in display
        ldi     SegArray                ; reset position
        st      Posn(1)
        jmp     Display-0F01h(1)        ; start again

; *****************************************************************************
;
;                         Game over. Return to Monitor
;
; *****************************************************************************
GameOver:
        ldi     0                       ; return to monitor
        st      8(1)                    ; fix for 9 digit displays
        xpal    3                       ; P3 is almost certainly corrupted.
        ldi     0                       ; so we'll enter at RESET 0001h
        xpah    3
        ld      Score(1)                ; save score so it can be read by
        st      TheScore+1              ; pressing 'MEM'
        xppc    3
TheScore:
        .db     0FFh                    ; score slot

        js      3,Start			        ; if then press MEM GO the program
        				                ; will be re-run

        .or    MoreRAM                 ; Rest of Code in extended memory

; *****************************************************************************
;
;                               Start Program
;
; *****************************************************************************

Start:  ldi     0Fh                     ; make P1 = 0F00h
        xpah    1
        ldi     0
        xpal    1

        ld      StartSpeed(1)   ; set the speed
        st      Speed(1)
        ldi     0FFh                    ; this is the 'end' marker.
        st      SegArray+8(1)
        ldi     0h                      ; clear the rest of the array
        st      SegArray+0(1)
        st      SegArray+1(1)
        st      SegArray+2(1)
        st      SegArray+3(1)
        st      SegArray+4(1)
        st      SegArray+5(1)
        st      SegArray+6(1)
        st      SegArray+7(1)
        st      Score(1)                ; zero the score
        st      Kb1(1)
        st      Kb3(1)

        ldi     6                       ; a starting piece
        st      SegArray+0(1)
        st      Shape(1)                ; this is its pattern
        ldi     0                       ; its here.
        st      Posn(1)

        js      3,Display		        ; jump into the main game code

; *****************************************************************************
;
;       Keyboard test. On entry, P1 = 0F00h and P2 = 0D00h. Checks for
;       new depressions and rotates the shape left or right accordingly
;
; *****************************************************************************
Keyboard:
        ldi     Kb1                     ; E = KB1 (so 80(P1) == KB1)
        xae
        ld      1(1)                    ; stops flickering
        ori     80h
        st      1(2)
        ld      1(2)                    ; Check row 1

KBTest: xri     255                     ; will be zero if no keys pressed
        jz      _NoKey
        ldi     64
_NoKey:                                 ; 040h if pressed 000h if not
        ;
        ; this section sets Kb1 or Kb3 [$80(P1)] so that bit 6 contains
        ; the current key value, and bit 7 contains the previous key value
        ;
        st      Temp(1)                 ; save this value
        ccl
        ld      80h(1)                  ; get the KB value
        add     80h(1)                  ; shift it left
        or      Temp(1)                 ; or the new one
        st      80h(1)                  ; and update it

        lde                             ; was last scan Kb1 ?
        xri     Kb1
        jnz     _KbCheck                ; if not finished scanning keys
        ldi     Kb3                     ; if it was we now scan Kb3
        xae
        ld      3(1)                    ; stops flickering
        ori     80h
        st      3(2)
        ld      3(2)                    ; Check row 3
        jmp     KBTest

_KbCheck:
        ld      15(2)                   ; fudge display brightness
        ld      Kb1(1)                  ; is key 1 just depressed
        xri     040h
        jz      _RotateLeft
        ld      Kb3(1)                  ; same for key 3
        xri     040h
        jz      _RotateRight
        xppc    3                       ; return
;
;       Shape Left
;
_RotateLeft:
        ccl
        ld      Shape(1)
        add     Shape(1)
        xae                             ; E=A=New Shape
        lde
        ani     03Fh
        xae                             ; E = New Shape * 2 & 0x3F
        ani     40h                     ; does bit 6 shift back ?
        jz      _NoSet1
        ldi     1
_NoSet1:
		ore
        jmp     ReplaceShape
;
;       Shape Right
;
_RotateRight:
        ld      Shape(1)
        sr
        ani     1Fh
        xae
        ld      Shape(1)
        ani     1
        jz      _NoSet2
        ldi     20h
_NoSet2:
		ore
        jmp     ReplaceShape
;
;       Update Shape
;
ReplaceShape:
        st      Temp(1)                 ; save the new shape

        ld      Posn(1)                 ; E = Posn $80(1) is now the display
        xae                             ; buffer for the current shape

        ld      80h(1)                  ; get the display value
        xor     Shape(1)                ; remove the old shape
        xor     Temp(1)                 ; put in the new shape
        st      80h(1)                  ; update the display value

        ld      Temp(1)                 ; update the new shape value
        st      Shape(1)

        xppc    3                       ; and return

; *****************************************************************************
;
;       Code to collapse the segments. This is put in I/O RAM
;
;       Tries to move each segment (left most first) down the display
;       as far as it can go. When it returns it goes back again to check
;       for more potential collapses.
;
; *****************************************************************************

CollapseCode:
        ldi     6                       ; start by moving segment no 6
        st      Temp(1)
_Collide1:
        ldi     0Fh                     ; set P2 to point to that segment
        xpah    2
        ld      Temp(1)
        xpal    2
        ld      0(2)                    ; if that segment is zero it doesn't
        jz      _CollNext               ; move
        xae                             ; put the segment data in E

        ;       shift piece at P2 to the right. Piece data in E

_Collide2:
        ld      1(2)                    ; are there any common segments so
        ane                             ; we can't shift the piece down ?
        jnz     _CollNext               ; if so, we can't move it.

        ld      0(2)                    ; remove the old shape
        xre
        st      0(2)
        ld      1(2)                    ; draw the new one
        xre
        st      1(2)
        ld      @1(2)                   ; bump P2 to point to the next one
        jmp     _Collide2               ; and try again.

_CollNext:                              ; test next segment
        dld     Temp(1)                 ; get next segment to the right to move
        jp      _Collide1               ; go back if 0..5
 
        xppc    3

        .end

