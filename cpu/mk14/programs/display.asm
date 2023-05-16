		.CR scmp
		.LF display.lst

Disp	.EQ		$100

start:
		HALT
loop:
		NOP
		JMP		loop

		.RF		Disp-$

		.DB		$01
		.DB		$02
		.DB		$03
		.DB		$04
		.DB		$05
		.DB		$06
		.DB		$07
		.DB		$08
