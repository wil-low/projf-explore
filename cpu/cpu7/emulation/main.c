#include "torth.h"
#include <stdio.h>

CHAR8 dest[2048];

UINT8 MEM8RD(UINT32 addr)
{
	return dest[addr];
}

void MEM8WR(UINT32 addr, UINT8 value)
{
	dest[addr] = value;
}

UINT16 MEM16RD(UINT32 addr)
{
	return dest[addr] + ((UINT16)dest[addr + 1]) << 8;
}

void MEM16WR(UINT32 addr, UINT16 value)
{
	dest[addr] = value & 0xff;
	dest[addr + 1] = value >> 8;
}

int main(int argc, char* argv[])
{
	CHAR8 buf[2048];
	CHAR8* source = &buf[0];

	UINT32 addr = 0;

	FILE * file;

	file = fopen(argv[1], "r");
	fread(buf, 1, sizeof(buf), file);
	printf("%s", buf);
	fclose(file);

	printf("source %lu\n", (UINT32)source);
	UINT8 err_code = torth_compile(&source, &addr);
	printf("err_code = %d, new source %lu\n", err_code, (UINT32)source);
	return err_code;
}
