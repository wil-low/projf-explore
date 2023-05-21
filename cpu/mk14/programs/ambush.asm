; ****************************************************************************
;
;       Ambush by Mark Williams
;
;       Game based on an ETI Electronics Project
;
;       Run from 0F18h
;
;       Byte at 0FD3h is the energy value
;       Byte at 0FD8h is the number of attackers
;
;       1 fire left,3 fire right,0 reset
;
; ****************************************************************************

Direction .equ    12h                   ; all these are offsets from P2
Delay     .equ    13h
NumLeft   .equ    14h
Energy    .equ    15h
DispShape .equ    16h
Count     .equ    17h

        .org    0F12h
        .db     01h,25h,14h,25h,3Fh,00h

Begin:  ldi     0Fh                     ; P2 = 0F00h
        xpah    2
        ldi     00h
        xpal    2
        ldi     0Dh                     ; P1 = 0D00h
        xpah    1
        ldi     00h
        xpal    1

        dld     Delay(2)                ; delay up ?
        jz      Cont-0F01h(2)           ; if so, attack

        ld      DispShape(2)            ; display your ship
        st      4(1)                    ; in the middle of the display
        dly     50h                     ; and wait

        ldi     0                       ; zero digits 1 and 3
        st      1(1)
        st      3(1)
        ld      1(1)                    ; check row 1
        xri     0FFh                    ; if '1' pressed
        jnz     DecFuel                 ; decrement fuel
        ld      3(1)                    ; if '3' pressed
        xri     0FFh                    ; decrement fuel, else skip over
        jz      GoBegin
DecFuel:
        ld      Energy(2)               ; if fuel gone....
        jz      DiffShape               ; use a different shape...
        dld     Energy(2)               ; decrement energy
        jmp     GoBegin
DiffShape:
        ldi     49h                     ; out of energy... new shape.
        st      DispShape(2)            ; we are in deep trouble here...
GoBegin:
        jmp     Begin-0F01h(2)          ; back to the start
;
;       Ship attacks !
;
Cont:
        ld      Direction(2)            ; get the direction
        jnz     Left                    ; if its left,do that bit
        ldi     1                       ; from the right
        st      Count(2)
        ldi     0                       ; position
        xae
        jmp     ContShip
Left:   ldi     0FFh                    ; the count is -1 for the left
        st      Count(2)
        ldi     09                      ; start from position 9
        xae
ContShip:
        ldi     40h                     ; speed rate
        st      Direction(2)
MainDisp:
        ld      DispShape(2)            ; display your ship
        st      4(1)
        dly     01h
        ldi     41h                     ; display your attacker
        st      80h(1)
        dly     01h
        ldi     0                       ; read the keyboard
        st      1(1)
        st      3(1)
        ld      Count(2)                ; which key should be pressed ?
        xri     0FFh
        jnz     Check3

        ld      1(1)                    ; check if '1' pressed
        xri     0FFh
        jnz     Hit                     ; if so, go to the hit part
        jmp     NoKey

Check3: ld      3(1)                    ; check if '3' pressed
        xri     0FFh
        jnz     Hit                     ; if so, go to the it part

NoKey:  dld     Direction(2)            ; decrement the direction (counter)
        jnz     MainDisp-0F01h(2)       ; if non-zero redisplay stuff

        ld      Count(2)                ; move attacker to the middle ....
        ccl
        ade
        xae
        lde
        xri     04h                     ; hit your ship ?
        jnz     ContShip-0F01h(2)       ; if not, try again

        ldi     HitMsg & 255            ; you've had it
        xpal    2                       ; display 'hit'.
        jmp     DispResult

Hit:    ld      Energy(2)               ; any energy left ?
        jz      NoKey                   ; if not, you can't defend yourself

        ld      Direction(2)            ; and direction from random number
        ani     03Fh                    ; to make the delay
        ccl
        adi     0Fh
        st      Delay(2)
        ld      Direction(2)            ; and also make the next direction
        ani     01h
        st      Direction(2)
        dld     NumLeft(2)              ; are there any left....
        jnz     Begin-0F01h(2)          ; if so, back to the beginning

        ldi     Survive & 255           ; you've won !
        xpal    2
DispResult:
        ldi     09h
NextDigit:
        xae
        ld      80h(2)
        st      80h(1)
        dly     01h
        lde
        jz      DispTest
        ldi     0FFh
        ccl
        ade
        jmp     NextDigit
DispTest:
        ild     0(1)                    ; check for 0 to be pressed
        jz      DispResult              ; if not, display the result again

        ldi     0                       ; reset the game
        xpal    2
        ldi     25h
        st      Delay(2)
        st      Direction(2)
        st      Energy(2)
        ldi     14h
        st      NumLeft(2)
        ldi     3Fh
        st      DispShape(2)
        jmp     Begin-0F01h(2)

HitMsg:
        .db     0,0,0,78h,06h,76h,0,0,0
Survive:
        .db     5eh,79h,3eh,6,3eh,31h,3eh,06Dh,0

        .end


