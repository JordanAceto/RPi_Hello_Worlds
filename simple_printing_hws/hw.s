@ simple hello world program in arm assembly for the raspberry pi 3b+

.text

.global _start

_start:
    mov r7, #4      @ sys call write to screen
    mov r0, #1      @ set outstream to monitor
    mov r2, #12     @ string length of msg
    ldr r1, =msg    @ the message to print
    swi 0           @ software interrupt

_end:
    mov r7, #1      @ exit to terminal 
    swi 0           @ software interrupt

.data

msg:
    .ascii "hello world\n"
