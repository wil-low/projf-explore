		.CR scmp
		.LF display.lst

Disp	.EQ		$100

start:
		HALT
		LDI		$1
		XPAH	2
		LDI		$00
		XPAL	2		
loop:
		NOP
		LDI		0b01000000
		ST		2(2)
		ST		5(2)

		LDI		12
		DLY		40

		LDI		$0
		ST		2(2)
		ST		5(2)

		LDI		12
		DLY		40

		JMP		loop

		.RF		Disp-$

		.DB		0b00000110
		.DB		0b01011011
		.DB		0b01001111
		.DB		0b01100110
		.DB		0b01101101
		.DB		0b01111101
		.DB		0b00000111
		.DB		0b01111111
