		; Multiplies 2 unsigned 8-bit numbers
		; (Relocatable)
		; Stack usage
		;		REL:		ENTRY:		USE:		RETURN:
		;		 -1						Temp
		;(P2)->	  0			A			A			A
		;		  1			B			B			B
		;		  2						Result(H)	Result(H)			
		;		  3						Result(L)	Result(L)			

		.CR scmp
		.LF multiply.lst

A		.EQ		0
B		.EQ		1
Temp	.EQ		-1
RH		.EQ		2
RL		.EQ		3

		.OR		0
start:
		HALT

		LDI		$10
		XPAH	2
		LDI		$00
		XPAL	2

;		CCL
;		LDI		200
;		XAE
;		LDI		100
;		ADE
;		HALT

		LDI		$FF
		ST		A(2)
		LDI		$FF
		ST		B(2)

		LDI		$99
		LD		A(2)

		JS		3,Mult
		LD		RH(2)
		XAE
		LD		RL(2)

		HALT

		; Multiply routine begins here
Mult:	LDI		8
		ST		Temp(2)
		LDI		0
		ST		RH(2)
		ST		RL(2)
Nbit:	LD		B(2)
		CCL
		RR
		ST		B(2)
		JP		Clear
		LD		RH(2)
		ADD		A(2)
Shift:	RRL
		ST		RH(2)
		LD		RL(2)
		RRL
		ST		RL(2)
		DLD		Temp(2)
		JNZ		Nbit
		RET		3
		JMP		Mult
Clear:	LD		RH(2)
		JMP		Shift
;
		.END
