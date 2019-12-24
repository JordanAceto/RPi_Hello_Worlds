
/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_Time_Get_Base_Addr

Function Description:
    Get a pointer to the base address of the System Timer Register region of memory

Inputs:
    None

Returns:
    pointer to the base address of the System Timer Register region of memory

Error Handling:
    None

Equivalent C function signature:
    void* PSP_Time_Get_Base_Addr(void)

-------------------------------------------------------------------------------------------------*/
.globl PSP_Time_Get_Base_Addr
PSP_Time_Get_Base_Addr:
    ldr     r0,     =0x3F003000     @ base of System Timer Register region of memory
    mov     pc,     lr



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_Time_Get_Timebase

Function Description:
    Get the 64 bit contents of the System Timer Counter

Inputs:
    None

Returns:
    The 64 bits of the System Timer Counter, CLO goes in r0, CHI goes in r1

Error Handling:
    None

Equivalent C function signature:
    uint64_t PSP_Time_Get_Timebase(void)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_Time_Get_Timebase
PSP_Time_Get_Timebase:
    push    {lr}

    bl      PSP_Time_Get_Base_Addr

    ldrd    r0,     r1,     [r0, #4]
    pop     {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_Time_Get_CLO

Function Description:
    Get the contents of the System Timer Counter lower 32 bits

Inputs:
    None

Returns:
    The lower 32 bits of the System Timer Counter

Error Handling:
    None

Equivalent C function signature:
    uint32_t PSP_Time_Get_CLO(void)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_Time_Get_CLO
PSP_Time_Get_CLO:
    push    {lr}

    bl      PSP_Time_Get_Base_Addr

    ldr     r0,     [r0, #4]
    pop     {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_Time_Get_CHI

Function Description:
    Get the contents of the System Timer Counter upper 32 bits

Inputs:
    None

Returns:
    The upper 32 bits of the System Timer Counter

Error Handling:
    None

Equivalent C function signature:
    uint32_t PSP_Time_Get_CHI(void)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_Time_Get_CHI
PSP_Time_Get_CHI:
    push    {lr}

    bl      PSP_Time_Get_Base_Addr

    ldr     r0,     [r0, #8]
    pop     {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_Time_Delay_Microseconds

Function Description:
    Wait for a specified number of microseconds

Inputs:
    delay_in_uSec: uint32_t time in uSec to wait

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void PSP_Time_Delay_Microseconds(uint32_t delay_in_uSec)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_Time_Delay_Microseconds
PSP_Time_Delay_Microseconds:
    uSec    .req    r2
    mov     uSec,   r0                  @ save input param delay_in_uSec in r2

    push    {lr}
    bl      PSP_Time_Get_Timebase       @ get the timebase

    start   .req    r3
    mov     start,  r0                  @ save the timebase reading in r3

    loop$:
        bl  PSP_Time_Get_Timebase
        elapsed     .req    r1
        sub     elapsed,    r0,     start
        cmp     elapsed,    uSec
        .unreq  elapsed
        bls     loop$

    .unreq  uSec
    .unreq  start
    pop     {pc}
