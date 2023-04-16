#include "torth.h"
#include "cpu7.h"
#include <stdio.h>
#include <string.h>

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

	for (int i = 0; i < 128; ++i) {
		if (instw[i][0]) {
			if (strcmp(instw[i], inst_name[i]) == 0)
				printf("`define i_%s 'h%02x\n", inst_name[i], i);
			else
				printf("`define i_%s 'h%02x\t// alias: %s\n", inst_name[i], i, instw[i]);
		}
		else {
			printf("// `define i_%s 'h%02x\n", instw[i], i);
		}
	}
	return 0;
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
