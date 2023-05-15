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

NumH		.EQ		 0
NumL		.EQ		 1
Delay		.EQ		 2
CurH		.EQ		-2
CurL		.EQ		-1
TempH		.EQ		-4
TempL		.EQ		-3

DelayA		.EQ		12
DelayShort	.EQ		4
DelayLong	.EQ		40

Collatz		.EQ		$0F70

start:
		HALT
							; P2 = $1000
		LDI		$10
		XPAH	2
		LDI		$00
		XPAL	2

		LDI		$03			; N = 1000 = $03e8
		ST		NumH(2)
		LDI		$E8
		ST		NumL(2)

		LDI		DelayA
		ST		Delay(2)

		JS		3,Collatz

		LDI		$81
		XAE
		HALT

		.RF		Collatz-$

Collatz:
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

		XAE
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
even:
							; divide by 2
		CCL
		LD		TempH(2)
		SRL
		ST		TempH(2)
		LD		TempL(2)
		RRL
		ST		TempL(2)

display:
		LD		TempL(2)
		XAE
		LD		Delay(2)
		DLY		DelayShort
							; check for Temp = 1
		LD		TempH(2)
		JNZ		check_oddity
		SCL
		LDI		1
		CAD		TempL(2)	; A == 1 ?
		JNZ		check_oddity

		XAE
		LD		Delay(2)
		DLY		DelayLong
							; check Cur == Num
		SCL
		LD		CurH(2)
		CAD		NumH(2)
		JNZ		next_cur
		
		SCL
		LD		CurL(2)
		CAD		NumL(2)
		JNZ		next_cur

		RET		3
