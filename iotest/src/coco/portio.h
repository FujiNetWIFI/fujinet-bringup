#include <coco.h>

#define PORT_INIT() port_init()

extern void port_init();

extern int port_getc();
extern int port_getc_timeout(uint16_t timeout);
extern uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout);

extern int port_putc(uint8_t c);
extern uint16_t port_putbuf(const void *buf, uint16_t len);

#define PORT_TICKS_PER_SECOND 32768
