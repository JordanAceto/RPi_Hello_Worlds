@ simple sign of life program for Raspberry Pi 3b+
@ uses PSP_GPIO and PSP_TIME modules to blink a
@ LED on GPIO17 in an sos pattern when a switch
@ on GPIO21 is pulled high



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

.equ        DELAY_TIME_mSec,    100


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

sos     .req    r4              @ sos pattern
ldr     sos,    =sos_pattern    @ load the address
ldr     sos,    [sos]           @ then load the actual contents

index   .req    r5              @ index into the sos pattern
mov     index,  #0              @ start at index 0


/***************************************************************************************************
 *
 *                                           Main Loop
 *
 ***************************************************************************************************/

loop$:                                  @ main loop label

mov     r0,     #SWITCH_PIN
bl      PSP_GPIO_Read_Pin               @ read the switch

mov     r1,     r0                      @ store the result in r1

mov     r0,     #LED_PIN                @ get set up to write to the LED
lsl     r1,     index                   @ shift the result of the switch read by the index
and     r1,     sos                     @ and check if the sos pattern is high at that shifted index
bl      PSP_GPIO_Write_Pin              @ LED turns on if the switch is high and the pattern at the index is high

add     index,  #1                      @ increment the index
and     index,  #31                     @ and wrap around when the index goes out of bounds

ldr     r0,     =#DELAY_TIME_mSec       @ kill time
bl      PSP_Time_Delay_Milliseconds

b       loop$                           @ go back to the top of the main loop


.section    .data
.align      2

sos_pattern:
.int    0b00000000010101011101110111010101  @ long pause, ...---...
