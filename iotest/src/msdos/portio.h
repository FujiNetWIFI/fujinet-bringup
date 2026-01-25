#include <stdint.h>

#define PORT_INIT() port_init(0x3F8, 1)

extern void cdecl port_init(uint16_t base, uint16_t divisor);

extern int cdecl port_getc();
extern int cdecl port_getc_timeout(uint16_t timeout);
extern uint16_t cdecl port_getbuf(void *buf, uint16_t len, uint16_t timeout);

extern int cdecl port_putc(uint8_t c);
extern uint16_t cdecl port_putbuf(const void *buf, uint16_t len);

#define PORT_TICKS_PER_SECOND 1000
