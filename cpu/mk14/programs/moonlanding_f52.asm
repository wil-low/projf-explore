	.CR scmp
	.TF moonlanding_f52.hex, INT
	;
	; Converted to SBASM by Slothie 2021
	;
	;Constants
Grav	.EQ 5		;Force of gravity
Disp	.EQ 0xD00	;Display address
Crom	.EQ 0x10B	;Segment table
E	.EQ -128	;Extension register as offset

;**Next 2 lines moved to bottom to eliminate fwd reference
;Row	.EQ Ret-0xF03	;Ram Offsets
;Count	.EQ Ret-0xF04
	;
	;Variables
	.OR 0xF05
	.DU
Save	.BS 1
H1	.BS 1
L1	.BS 1
Alt	.BS 3		;Altitude
Vel	.BS 3		;Velocity
Accn	.BS 2		;Acceleration
Thr	.BS 2		;Thrust
Fuel	.BS 2		;Fuel Left
	.ED
	;
	; Initial values
	.OR 0xF14
Init	.DB 0x08, 0x50, 0x00	; Altitude = 850
	.DB 0x99, 0x80, 0x00	; Velocity = -20
	.DB 0x99, 0x98		; Acceleration = -2
	.DB 0x00, 0x02		; Thrust = 2
	.DB 0x58, 0x00		; Fuel = 5
Ret	XPPC 2			; P2 contains 0F20
Displ	ST Save
	LDI /Crom
	XPAH 1
	ST H1		; Run out of pointers
	LDI #Crom
	XPAL 1
	ST L1
	LD Save
	CCL
	ANI 0x0F
	XAE
Loop	LD E(1)
	ST @+1(3)
	LDI 0		;Delay point
	DLY 4		;Determines speed
	LD Save
	SR
	SR
	SR
	SR
	XAE
	CSA
	SCL
	JP Loop		;Do it twice
	LDI 0
	ST @+1(3)	;Blank between
	LD H1		;Restores P1
	XPAH 1
	LD l1
	XPAL 1
	JMP Ret		;Return
	; Main moon landing program
Start:	LDI /Init
	XPAH 1
	LDI #Init
	XPAL 1
	LDI /Ret
	XPAH 2
	LDI #Ret
	XPAL 2
	LDI 12
	ST Count(2)
Set	LD +11(1)
	ST @-1(1)
	DLD Count(2)
	JNZ Set
;Main Loop
Again	LDI /Disp-1
	XPAH 3
	LDI #Disp-1
	XPAL 3
	LDI 1
	ST Count(2)
	LD @+6(1)	;P1->Vel+2
	JP Twice	;Altitude positive?
	LD @+4(1)	;P1->Thr+1
	JMP Off		;Don't update
Twice	LDI 2		;Update velocity anc
	ST Row(2)	;Then altitude...
	CCL
Dadd	LD @-1(1)
	DAD +2(1)
	ST (1)
	DLD Row(2)
	JNZ Dadd
	LD +2(1)
	JP Pos		;Gone negative?
	LDI 0x99
Pos	DAD @-1(1)
	ST (1)
	DLD Count(2)
	JP Twice
	LD @12(1)	;P1->Alt
	ILD Row(2)	;Row = 1
	SCL
Dsub	LD @-1(1)	;Fuel	
	CAD -2(1)	;Subtract thrust
	ST (1)
	NOP
	DLD Row(2)
	JP Dsub
	CSA		;P1->Fuel now
	JP Off		;Fuel run out?
	JMP Accns
Off	LDI 0
	ST -1(1)	;Zero thrust
Accns	LD -1(1)
	SCL
	DAI 0x99-Grav
	ST -3(1)	;Accn + 1
	LDI 0x99
	DAI 0
	ST -4(1)	;Accn
Dispy	LD (1)		;Fuel
	XPPC 2		;Display it OK
	LD -7(1)	;Vel
	JP Posv
	LDI 0x99
	SCL
	CAD -6(1)	;Vel+1
	SCL
	DAI 0
	JMP Sto
Posv	LD -6(1)	;Vel+1
Sto	XPPC 2		;Display velocity
	LD -9(1)	;Alt+1
	XPPC 2		;Display it
	LD @-1(3)	;Get rid of lank
	LD @-10(1)	;P1->Alt now
	XPPC 2
	LDI 10
	ST Count(2)
Toil	LD @-1(3)	;Key pressed?
	JP Press	;Key 0-7?
	XRI 0xDF	;Command key?
	JZ rStart(2)	;Begin again if so
	DLD Count(2)
	JNZ Toil
	JMP rAgain(2)	;Another circuit
Press	LD +9(1)	;Thr+1
	JZ Back		;Engines stopped?
	XPAL 3		;Which Row?
	ST +9(1)	;Set thrust
Back	JMP rAgain(2)

; These lines moved here to eliminate forward references
; that SBASM complains about.
; Also the SoC listing has the subtraction backwards!
; These values are the offset relative to P1 which points to
; 0xF20, or the Ret label. All variables are stored before this
; memory location at -ve offsets.
Row	.EQ 0xF03-Ret	;Ram Offsets
Count	.EQ 0xF04-Ret
;
; these calcs done to fix the way SBASM does calculations.	
rAgain	.EQ Again-Ret-1
rStart 	.EQ Start-Ret-1

	.OR 0xFFFE
	.DB Start/256
	.DB Start
