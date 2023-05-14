		.CR scmp
		.LF test.lst

start:
		HALT
		LDI $1f
		ADI $55
		XAE
		LDI $22
		ADE
		LD start
