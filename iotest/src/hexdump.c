#include "hexdump.h"
#ifndef _CMOC_VERSION_
#include <stdio.h>
#endif /* _CMOC_VERSION_ */

#define COLUMNS 16

void hexdump(void *buffer, int count)
{
  int outer, inner;
  uint8_t c, *ptr = (uint8_t *) buffer;


  for (outer = 0; outer < count; outer += COLUMNS) {
    for (inner = 0; inner < COLUMNS; inner++) {
      if (inner + outer < count) {
	c = ptr[inner + outer];
	printf("%02x ", c);
      }
      else
	printf("   ");
    }
    printf(" |");
    for (inner = 0; inner < COLUMNS && inner + outer < count; inner++) {
      c = ptr[inner + outer];
      if (c >= ' ' && c <= 0x7f)
	printf("%c", c);
      else
	printf(".");
    }
    printf("|\n");
  }

  return;
}
