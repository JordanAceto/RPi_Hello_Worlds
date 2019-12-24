@ simple sign of life program for Raspberry Pi 3b+
@ blinks a LED on GPIO17 using PSP_GPIO and PSP_TIME modules
@ or turns a led on and off with a switch on GPIO21
@ depending on what I'm working on at the moment

.section    .init
.globl      _start

_start:

/***************************************************************************************************
 *
 *                                           Setup
 *
 ***************************************************************************************************/
 
b main

.section    .text

main:
mov     sp,     #0x8000         @ set stack pointer to initial value

mov     r0,     #21             @ pin num, gpio 21
mov     r1,     #0              @ pin mode, 0 for input
bl      PSP_GPIO_Set_Pin_Mode   @ set gpio 21 to input

mov     r0,     #17             @ pin num, gpio 17
mov     r1,     #1              @ pin mode, 1 for output
bl      PSP_GPIO_Set_Pin_Mode   @ set gpio 17 to output


/***************************************************************************************************
 *
 *                                           Main Loop
 *
 ***************************************************************************************************/

loop$:                                  @ main loop label

mov     r0,     #21
bl      PSP_GPIO_Read_Pin               @ read pin 21

mov     r1,     r0                      @ store the result in r1

mov     r0,     #17
bl      PSP_GPIO_Write_Pin              @ write the value to pin 17

b       loop$                           @ go back to the top of the main loop


.section    .data
.align      2
