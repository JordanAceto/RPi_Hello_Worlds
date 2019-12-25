@ simple sign of life program for Raspberry Pi 3b+
@ blinks a LED on GPIO17 using PSP_GPIO and PSP_TIME modules
@ or turns a led on and off with a switch on GPIO21
@ depending on what I'm working on at the moment


/***************************************************************************************************
 *
 *                                     Constant Definitions
 *
 ***************************************************************************************************/
.equ        GPIO_INPUT,         0
.equ        GPIO_OUTPUT,        1

.equ        GPIO_LOW,           0
.equ        GPIO_HIGH,          1

.equ        SWITCH_PIN,         21
.equ        LED_PIN,            17

.equ        DELAY_TIME_uSec,    1000000


/***************************************************************************************************
 *
 *                                           Setup
 *
 ***************************************************************************************************/
 
.section    .init
.globl      _start

_start:
 
b main

.section    .text

main:
mov     sp,     #0x8000         @ set stack pointer to initial value

mov     r0,     #SWITCH_PIN
mov     r1,     #GPIO_INPUT
bl      PSP_GPIO_Set_Pin_Mode   @ set gpio 21 to input

mov     r0,     #LED_PIN
mov     r1,     #GPIO_OUTPUT
bl      PSP_GPIO_Set_Pin_Mode   @ set gpio 17 to output

mov     r4,     #GPIO_HIGH      @ led signal, this will toggle to set led on/off (for the blinky part)



/***************************************************************************************************
 *
 *                                           Main Loop
 *
 ***************************************************************************************************/

loop$:                                  @ main loop label

mov     r0,     #SWITCH_PIN
bl      PSP_GPIO_Read_Pin               @ read pin 21

mov     r1,     r0                      @ store the result in r1

mov     r0,     #LED_PIN
bl      PSP_GPIO_Write_Pin              @ write the value to pin 17

@ button above
@+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
@ blinky below

@ eor     r4,     r4,     #1              @ toggle the led signal by xor'ing it with 1

@ mov     r0,     #LED_PIN
@ mov     r1,     r4                      @ the led signal, 0 or 1
@ bl      PSP_GPIO_Write_Pin              @ write to the led

@ ldr     r0,     =#DELAY_TIME_uSec
@ bl      PSP_Time_Delay_Microseconds

b       loop$                           @ go back to the top of the main loop


.section    .data
.align      2
