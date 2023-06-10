		; Collatz sequence visualizer
		; (Relocatable)
		; Stack usage
		;		REL:		ENTRY:		USE:		RETURN:
		;		 -4						Temp(H)
		;		 -3						Temp(L)
		;		 -2						Cur(H)
		;		 -1						Cur(L)
		;(P2)->	  0			Num(H)		Num(H)		Num(H)
		;		  1			Num(L)		Num(L)		Num(L)
		;		  2			DelayShort		DelayShort		DelayShort

		.CR scmp
		.LF collatz.lst
		.TF collatz.hex,INT

NumH		.EQ		 0
NumL		.EQ		 1
Delay		.EQ		 2
CurH		.EQ		-2
CurL		.EQ		-1
TempH		.EQ		-4
TempL		.EQ		-3

Show		.EQ		 9

DelayA		.EQ		$F0
DelayShort	.EQ		$80
DelayLong	.EQ		$F0

		.OR		$0F20

Collatz:
							; P1 = $0D00
		LDI		$0D
		XPAH	1
		LDI		$00
		XPAL	1

							; P2 = $0F10
		LDI		$0F
		XPAH	2
		LDI		$10
		XPAL	2

		LDI		$03			; N = 1000 = $03e8
		ST		NumH(2)
		LDI		$E8
		ST		NumL(2)

		LDI		DelayA
		ST		Delay(2)

		LDI		0
		ST		CurH(2)
		LDI		2
		ST		CurL(2)
next_cur:					
							; increase Cur
		CCL
		LDI		1
		ADD		CurL(2)
		ST		CurL(2)
		LDI		0
		ADD		CurH(2)
		ST		CurH(2)
							; copy Cur => Temp
		LD		CurH(2)
		ST		TempH(2)
		LD		CurL(2)
		ST		TempL(2)

		ST		Show(1)
		LD		Delay(2)
		DLY		DelayLong
		LD		Delay(2)
		DLY		DelayLong
		LD		Delay(2)
		DLY		DelayLong

check_oddity:
							; oddity check
		LDI		1
		AND		TempL(2)
		JZ		even
							; odd, multiple by 3
		CCL
		LD		TempL(2)
		XAE
		LD		TempL(2)
		ADE
		ST		TempL(2)	; TempL * 2, E = TempL, CY_L set

		LD		TempH(2)
		XPAL	1
		LD		TempH(2)
		ADD		TempH(2)	; with CY_L
		ST		TempH(2)	; TempH * 2, P1 = TempH

		CCL
		LD		TempL(2)
		ADE
		ST		TempL(2)	; TempL * 3, E = TempL, CY_L set

		XPAL	1
		ADD		TempH(2)	; with CY_L
		ST		TempH(2)	; TempH * 3, P1 = TempH
							; increase Temp
		CCL
		LDI		1
		ADD		TempL(2)
		ST		TempL(2)
		LDI		0
		ADD		TempH(2)
		ST		TempH(2)

		JMP		display
next_cur1:
		JMP		next_cur
even:
							; divide by 2
		CCL
		LD		TempH(2)
		RRL
		ST		TempH(2)
		LD		TempL(2)
		RRL
		ST		TempL(2)

display:
		LD		TempL(2)
		ST		Show(1)
		LD		Delay(2)
		DLY		DelayShort
							; check for Temp = 1
		LD		TempH(2)
		JNZ		check_oddity
		SCL
		LDI		1
		CAD		TempL(2)	; A == 1 ?
		JNZ		check_oddity

		ST		Show(1)
		LD		Delay(2)
		DLY		DelayLong
		LD		Delay(2)
		DLY		DelayLong
		LD		Delay(2)
		DLY		DelayLong
							; check Cur == Num
		SCL
		LD		CurH(2)
		CAD		NumH(2)
		JNZ		next_cur1
		
		SCL
		LD		CurL(2)
		CAD		NumL(2)
		JNZ		next_cur1

		LDI		$81
		ST		Show(1)
		HALT
