@ simple sign of life program for Raspberry Pi 3b+
@ blinks a LED on GPIO17 using PSP_GPIO and PSP_TIME modules

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

mov     r0,     #17             @ pin num, gpio 17
mov     r1,     #1              @ pin mode, 1 for output, 0 for input
bl      PSP_GPIO_Set_Pin_Mode   @ call the function to set gpio 17 to an output

mov     r4,     #1              @ led signal, this will toggle to set led on/off



/***************************************************************************************************
 *
 *                                           Main Loop
 *
 ***************************************************************************************************/

loop$:                                  @ main loop label

eor     r4,     r4,     #1              @ toggle the led signal by xor'ing it with 1

mov     r0,     #17                     @ pin num, gpio 17
mov     r1,     r4                      @ the led signal, 0 or 1
bl      PSP_GPIO_Write_Pin              @ write to the led

ldr     r0,     =#100000                @ wait
bl      PSP_Time_Delay_Microseconds

b       loop$                           @ go back to the top of the main loop


.section    .data
.align      2


