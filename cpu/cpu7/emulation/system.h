#ifndef _SYSTEM_H
#define _SYSTEM_H

#define CORES 4
#define MEMSIZE 1024
#define DLY_RESOLUTION 1
#define CALL_STACK_SIZE 16
#define DATA_STACK_SIZE 16

UINT8 MEM8RD(UINT32 addr);
void MEM8WR(UINT32 addr, UINT8 value);
UINT16 MEM16RD(UINT32 addr);
void MEM16WR(UINT32 addr, UINT16 value);

#endif
