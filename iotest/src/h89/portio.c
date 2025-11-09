#include "portio.h"
#include <arch/z80.h>
#include <stdlib.h>

#define IOPORT 0xD0
#define PORTA IOPORT
#define PORTB IOPORT+1
#define PORTC IOPORT+2
#define PCTRL IOPORT+3

#define OUTBUF_FULL 0x80 // i8255 wants to send, /OBF, output active low
#define OUTBUF_ACK  0x40 // ESP32 received the byte, /ACK, input active low
#define INBUF_FULL  0x20 // i8255 received the byte, IBF, output active high
#define INBUF_GET   0x10 // ESP32 wants to send, /STB, input active low

#define DATA_DIR    0x01
#define DATA_EN     0x02
#define ESP32_EN    0x04

#define I8255_G2_PORTC_INPUT 0x01
#define I8255_G2_PORTB_INPUT 0x02
#define I8255_G2_MODE_1      0x04
#define I8255_G1_PORTC_INPUT 0x08
#define I8255_G1_PORTA_INPUT 0x10
#define I8255_G1_MODE_1      0x20
#define I8255_G1_MODE_2      0x40
#define I8255_MODE_ACTIVE    0x80

// 74LVC245 Direction
enum {
  ESP32_TO_H89 = 0,
  H89_TO_ESP32 = 1,
  NONE_TO_NONE = 2,
};

#define OE_ENABLE 2
#define OE_DISABLE 3

// Jiffy Counter
#define TIKCNT 0x000B    // H89 Jiffy Counter under CP/M.

unsigned char current_dir = 0;
unsigned char out_enabled = 0;

void port_set_direction(unsigned char dir)
{
    if (dir == current_dir)
       return;

    if (dir == NONE_TO_NONE) {
      z80_outp(PCTRL, OE_DISABLE);
      out_enabled = 0;
    }
    else {
      if (!out_enabled) {
        z80_outp(PCTRL, OE_ENABLE);
        out_enabled = 1;
      }

      z80_outp(PCTRL,dir);
    }

    // msleep(200);

    current_dir = dir;
}

void port_init()
{
  z80_outp(PCTRL,I8255_MODE_ACTIVE | I8255_G1_MODE_2);
  z80_outp(PORTC,DATA_EN | ESP32_EN);
  z80_outp(PORTC,DATA_EN);
  z80_outp(PORTC,DATA_EN | ESP32_EN);
  msleep(200);
  z80_inp(PORTA); // Flush input

  z80_outp(PCTRL,0x00); // SET DIR
  z80_outp(PCTRL,OE_DISABLE); // SET OE

  return;
}

int port_getc()
{
  int b = -1;

  if (z80_inp(PORTC) & INBUF_FULL)
  {
      port_set_direction(H89_TO_ESP32);
      b = z80_inp(PORTA);
      port_set_direction(NONE_TO_NONE);
  }

  return b;
}

int port_getc_timeout(uint16_t timeout)
{
    int b=-1;
    uint16_t start;


    // Store start time so we can calculate delta even when TIKCNT overflows
    start = wpeek(TIKCNT);

    while ((wpeek(TIKCNT) - start) < timeout)
    {
        b = port_getc();
        if (b > -1)
            return b;
    }
    return b;
}

uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout)
{
  uint16_t idx;
  int b;
  uint8_t *ptr = (uint8_t *) buf;

  for (idx = 0; idx < len; idx++) {
    b = port_getc_timeout(timeout);
    if (b < 0)
      break;
    ptr[idx] = b;
  }

  return idx;
}

void port_putc(uint8_t c)
{
    port_set_direction(H89_TO_ESP32);

    while (!(z80_inp(PORTC) & OUTBUF_FULL)); // Wait for ready to handle byte

    z80_outp(PORTA,c);

    port_set_direction(NONE_TO_NONE);

    return;
}

uint16_t port_putbuf(void *buf, uint16_t len)
{
  uint16_t idx;
  uint8_t *ptr = (uint8_t *) buf;


  for (idx = 0; idx < len; idx++)
    port_putc(ptr[idx]);
  return idx;
}
