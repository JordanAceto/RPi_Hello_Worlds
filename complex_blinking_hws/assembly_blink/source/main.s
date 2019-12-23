@ simple sign of life program for Raspberry Pi 3b+
@ blinks a LED on GPIO17

.section    .init
.globl      _start

_start:

/***************************************************************************************************
 *
 *                                           Setup
 *
 ***************************************************************************************************/
 
ldr     r0,     =0x3F200000     @ address of GPFSEL0, this is the base of gpio region (pi 3b+)

mov     r1,     #1              @ set pin 17 as output by writing a high bit to GPFSEL1 bit 21
lsl     r1,     #21             @ (gpio17 % 10) * 3 = 21 (10 gpio pins per GPFSEL reg, each pin gets 3 bits)
str     r1,     [r0, #4]        @ GPFSEL1 is at 0x3F200004, gpio17 is now an output

mov     r1,     #1              @ to turn the led on and off, we'll need to set the 17th bit of 
lsl     r1,     #17             @ GPSET0 and GPCLR0, so stash (1 << 17) in r1 for use later

/***************************************************************************************************
 *
 *                                           Main Loop
 *
 ***************************************************************************************************/

loop$:                          @ main loop

str     r1,     [r0, #0x1C]     @ GPSET0 is at 0x3F20001C, the led on gpio17 should now be on

mov     r2,     #0x003F0000     @ delay loop 1, put a large number in r2
wait1$:                         @ label for delay loop 1
sub     r2,     #1              @ decrement r2
cmp     r2,     #0              @ check to see if it is zero
bne     wait1$                  @ if it is not zero, keep decrementing, else fall through to the next instruction

str     r1,     [r0, #0x28]     @ GPCLR0 is at 0x3F200028, the led on gpio17 should now be off

mov     r2,     #0x003F0000     @ delay loop 2, same as delay loop 1
wait2$:
sub     r2,     #1
cmp     r2,     #0
bne     wait2$

b       loop$                   @ go back to the top of the main loop
