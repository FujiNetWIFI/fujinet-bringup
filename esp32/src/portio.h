#ifndef PORTIO_H
#define PORTIO_H

#include <stdint.h>

extern void portio_init();
extern int bus_available();
extern int port_getc();
extern int port_getc_timeout(uint16_t t);
extern uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout);
extern int port_putc(uint8_t c);
extern uint16_t port_putbuf(const void *buf, uint16_t len);

#endif /* PORTIO_H */
