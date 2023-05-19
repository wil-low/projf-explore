		.CR scmp
		.LF display.lst

start:
		HALT
		LDI		$d
		XPAH	2
		LDI		$00
		XPAL	2

		LDI		0b00000110
		ST		0(2)
		LDI		0b01011011
		ST		1(2)
		LDI		0b01001111
		ST		2(2)
		LDI		0b01100110
		ST		3(2)
		LDI		0b01101101
		ST		4(2)
		LDI		0b01111101
		ST		5(2)
		LDI		0b00000111
		ST		6(2)
		LDI		0b01111111
		ST		7(2)
loop:
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
