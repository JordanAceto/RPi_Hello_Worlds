@ simple sign of life program for Raspberry Pi 3b+
@ uses PSP_GPIO and PSP_TIME modules to blink a
@ LED on GPIO17 in an sos pattern when a switch
@ on GPIO21 is pulled high.
@ also fades a LED on pin12 with PWM.
@ also repeatedly sends the bytes "DEAD" via SPI0.



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

.equ        PATTERN_LEN_MIN_1,  31

.equ        PWM_MAX_VAL,        255


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
mov         sp,         #0x8000         @ set stack pointer to initial value

bl          BSP_PWM_Clock_Init          @ init PWM and set pin 12 to PWM output
bl          BSP_PWM_Ch1_Start
bl          BSP_PWM_Ch1_Set_GPIO12_To_PWM_Mode

mov         r0,         #SWITCH_PIN
mov         r1,         #GPIO_INPUT
bl          PSP_GPIO_Set_Pin_Mode       @ set gpio 21 to input

mov         r0,         #LED_PIN
mov         r1,         #GPIO_OUTPUT
bl          PSP_GPIO_Set_Pin_Mode       @ set gpio 17 to output

sos         .req        r4              @ sos pattern
ldr         sos,        =sos_pattern    @ load the address
ldr         sos,        [sos]           @ then load the actual contents

index       .req        r5              @ index into the sos pattern
mov         index,      #0              @ start at index 0

pwm_val     .req        r6              @ pwm value for pin 12, 0 to 255
mov         pwm_val,    #0              @ start at 0

bl          BSP_SPI0_Start              @ initialize spi0

ldr         r0,         =1024
bl          BSP_SPI0_Set_Clock_Divider


/***************************************************************************************************
 *
 *                                           Main Loop
 *
 ***************************************************************************************************/

loop$:                                   @ main loop label

mov     r0,         #SWITCH_PIN
bl      PSP_GPIO_Read_Pin               @ read the switch

mov     r1,         r0                  @ store the result in r1

mov     r0,         #LED_PIN            @ get set up to write to the LED
lsl     r1,         index               @ shift the result of the switch read by the index
and     r1,         sos                 @ and check if the sos pattern is high at that shifted index
bl      PSP_GPIO_Write_Pin              @ LED turns on if the switch is high and the pattern at the index is high

add     index,      #1                  @ increment the index
and     index,      #PATTERN_LEN_MIN_1  @ and wrap around when the index goes out of bounds

mov     r0,         pwm_val             @ fade the LED on pin 12 via pwm 
bl      BSP_PWM_Ch1_Write

add     pwm_val,    #1                  @ increment the pwm value
and     pwm_val,    #PWM_MAX_VAL        @ wrap around at 256

mov     r0,         #0xDE               @ write message of death via spi0
bl      BSP_SPI0_Transfer_Byte

mov     r0,         #0xAD
bl      BSP_SPI0_Transfer_Byte

ldr     r0,         =#DELAY_TIME_mSec   @ kill time
bl      PSP_Time_Delay_Milliseconds

b       loop$                           @ go back to the top of the main loop


.section    .data
.align      2

sos_pattern:
.int    0b00000000010101011101110111010101  @ long pause, ...---...
