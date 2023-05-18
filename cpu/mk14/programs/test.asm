		.CR scmp
		.LF test.lst

start:
		HALT
		JMP J
							; P2 = $1000
		LDI		$10
		XPAH	2
		LDI		$00
		XPAL	2

		LDI		$22
		ST		5(2)
		LDI		8
		XAE

		LDI		0
		LD		5(2)

		LDI		0
		LD		E(2)

		LD		@5(2)
j:
		LD		@-5(2)

		HALT

