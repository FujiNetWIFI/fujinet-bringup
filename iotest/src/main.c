#include "portio.h"
#include "hexdump.h"
#ifndef _CMOC_VERSION_
#include <stdio.h>
#endif /* _CMOC_VERSION_ */
#ifdef __WATCOMC__
#include <conio.h>
int getk();
#else /* ! __WATCOMC__ */
#ifndef _CMOC_VERSION_
#include <input.h>
#else /* _CMOC_VERSION_ */
#define getk() inkey()
#endif /* ! _CMOC_VERSION_ */
#endif /* __WATCOMC__ */

uint8_t buffer[512];

int main()
{
  int v;
  uint8_t c;
  unsigned int rlen, idx;


  PORT_INIT();

  printf("Waiting for data\n");
  port_putbuf("Send me data!\r\n", 15);

  while (1) {
    c = getk();
    if (c) {
      printf("Key $%02X\n", c);
      if (c == '@')
        port_putbuf("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123\r\n", 32);
      else
        port_putc(c);
      continue;
    }

    rlen = port_getbuf(buffer, sizeof(buffer), PORT_TICKS_PER_SECOND);
    if (rlen) {
#if 1
      for (idx = 0; idx < rlen; idx++)
        printf("$%02X ", buffer[idx]);
      printf("\n");
#endif
      printf("count: %u\n", rlen);
      if (rlen <= 16)
        hexdump(buffer, rlen);
      printf("sending back\n");
      port_putbuf(buffer, rlen);
    }
    else
      printf("timeout\n");
  }

  return 0;
}

#ifdef __WATCOMC__
int getk()
{
  if (kbhit())
    return getch();
  return 0;
}
#endif /* __WATCOMC__ */
