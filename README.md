So you've decided you want to port FujiNet to your favorite
RetroBattlestation? Well you're in luck, we've prepared this
step-by-step guide just for *you*!

This repo contains simple example code intended to be modified to get you going as quickly as possible. There are three parts to it:

1. The `iotest` folder. This contains the software that will run on your RetroBattlestation and send and receive data.
2. The `esp32` folder. This contains minimal firmware for simply relaying bytes between the RetroBattlestation bus via GPIO to the USB serial interface.
3. The `rp2350` folder. Similar to the `esp32` folder, it is firmware to relay bytes.

The first thing you need to determine is what electrical interface
you're going to connect to on your RetroBattlestations. Depending on
how many signal lines need to be managed will also determine whether
an ESP32 or an RP2350 is a better fit. If there are more than eight
lines, we recommend using an RP2350.

## Two-Way Communications ##

Once you've got things wired up, the next thing to do is establish two-way communication between your RetroBattlestation and a computer over the bus.

1. Port the iotest to your platform and create a `portio.c` or `portio.s` and fill in appropriate `port_*` routines. You can write the routines in C or assembly, whichever is easier. For IO speed it is recommended to use assembly, but C routines can be swapped out later.

2. Write matching routines for either the ESP32 or RP2350, depending on which you're using for the bus interface.

3. Debug debug debug. You should be able to push a key on your RetroBattlestation and have it send to your microcontroller. Similarly, data sent to the microcontroller over the USB interface should get sent to your RetroBattlestion.

## The Firmware ##

Congratulations, with two-way communications working you've accomplished the hardest part!

From here what you'll want to do is drop the portio routines into lib-experimental. Compile the FujiNet Hello World program which sends out a command packet to fetch the FujiNet firmware information and print it.

On your computer, compile the RS232 LWM version of the firmware, and point it to the USB port of your microcontroller. When you run the Hello World program you should see the firmware version and other information print on your RetroBattlestation!
