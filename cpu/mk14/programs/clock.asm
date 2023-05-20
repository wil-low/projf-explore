; Digital Alarm Clock from the MK14 Manual

		.CR scmp
		.LF clock.lst

CROM	.EQ	$010B			; Segment table in SCIOS
DISP	.EQ	$0D00			; Display
DISPD	.EQ	$0D0D			; Display

ROW		.EQ $0F10
	.OR	$0F00

	.RF	$0F12-$
	.DB	0			; Alarm hours
	.DB	0			; Alarm mins
	.DB	0			; Alarm secs
	.DB	0			; Not used
TIM:	.DB	$12			; Hours
	.DB	0			; Mins
	.DB	0			; Seconds
	.DB	0
TIM4:	.DB	$76			; 24 hours (bump up)
	.DB	$40			; 60 mins
	.DB	$40			; 60 seconds
SPEED:	.DB	$20			; Display cycles/second (80)

	.RF $0F20-$
CLOCK:
	LDI	/CROM		; 3 points to segment table
	XPAH	3
	LDI	#CROM
	XPAL	3
;
; This basic loop has been cycle trimmed for 12.5msec on 4MHz SC/MP
; This makes for a dim if precise display!
;
NEW:
	LDI	/DISP	; 2 points just before display
	XPAH	2			; Three invisible digits are
	LDI	#DISP	;  written to display
	XPAL	2

	LDI		0
	ST	2(2)
	ST	5(2)

	LDI	/DISPD	; 2 points just before display
	XPAH	2			; Three invisible digits are
	LDI	#DISPD	;  written to display
	XPAL	2

	LDI	/TIM4
	XPAH	1
	LDI	#TIM4
	XPAL	1

	SCL				; Ensure first digit increments
	LDI	5			; Display field loop counter
	ST	ROW
AGAIN:	LD	@-1(1)			; Increment digit pair
	DAI	0
	ST	0(1)
	DAD	4(1)			; Bump up
	JZ	CS			; Zero means roll-over
	JZ	CS			; (Equalise cycles)
	JMP	CONT
CS:	ST	0(1)			; Roll over - reset to zero NB. CY/L is set
CONT:	LD	0(1)			; Display digit pair
	ANI	$0F
	XAE
	LD	-128(3)
	ST	@1(2)
	LDI	$40
	DLY	0
	LD	0(1)
	SR
	SR
	SR
	SR
	XAE
	LD	-128(3)
	ST	@2(2)			; Leave a gap.
	DLD	ROW			; Next digit pair.
	JNZ	AGAIN
	LDI	3			; Prepare for alarm loop
	ST	ROW
	LDI	0
	XAE
LOOP:	LD	@-1(1)			; Compare digit pair.
	XOR	4(1)			; Zero here means same
	ORE				; Or 'em all up!
	XAE				; Keep OR-up in EXT
	DLD	ROW
	JNZ	LOOP
	XAE				; Check final result.
	JZ	ALARM			; Zero means alarm time!
	LDE
	JMP	CONTIN			; Select 0 or 7 here
ALARM:	LDI	$07
	NOP
CONTIN:	CAS				; Raise F0, F1 and F2 if alarm
	LDI	37			;  time
	DLY	23
	JMP	NEW

	.END
