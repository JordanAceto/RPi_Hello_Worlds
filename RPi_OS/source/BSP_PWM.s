
/*-----------------------------------------------------------------------------------------------
    BSP_PWM Constants
 -------------------------------------------------------------------------------------------------*/
.equ        BSP_PWM_CTL,        0x3F20C000
.equ        BSP_PWM_STA,        0x3F20C004
.equ        BSP_PWM_DMAC,       0x3F20C008
.equ        BSP_PWM_RNG1,       0x3F20C010
.equ        BSP_PWM_DAT1,       0x3F20C014
.equ        BSP_PWM_FIF1,       0x3F20C018
.equ        BSP_PWM_RNG2,       0x3F20C020
.equ        BSP_PWM_DAT2,       0x3F20C024

.equ        BSP_CM_PWMCTL,      0x3F1010A0
.equ        BSP_CM_PWMDIV,      0x3F1010A4

.equ        BSP_CM_PASSWD,      0x5A000000



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Clock_Init

Function Description:
    Initialize the PWM clock source to internal oscillator divided down to 4.8MHz and start the PWM clock.

    This function must be called before starting PWM channel 1 or 2, setting any GPIO pins to PWM mode or 
    writing any pins via PWM.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Clock_Init(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Clock_Init
BSP_PWM_Clock_Init:
    cm_pwmctl_addr  .req                r0
    ldr             cm_pwmctl_addr,     =BSP_CM_PWMCTL

    cm_passwd       .req                r1
    ldr             cm_passwd,          =BSP_CM_PASSWD

    cm_pwmctl_read  .req                r2
    ldr             cm_pwmctl_read,     [cm_pwmctl_addr]

    mask            .req                r3
    ldr             mask,               =0x00FFFFEF                 @ mask saves CM_PWMCTL except pwd and clears ENAB

    and             mask,               mask,   cm_pwmctl_read
    orr             mask,               mask,   cm_passwd
    str             mask,               [cm_pwmctl_addr]            @ request stop clock
    .unreq          mask                @ free r3

    wait_for_clock_to_stop:
        ldr         cm_pwmctl_read,     [cm_pwmctl_addr]
        and         cm_pwmctl_read,     cm_pwmctl_read, #0x80       @ busy flag in CTL reg
        cmp         cm_pwmctl_read,     #0x80                       @ loop until busy flag is low
        beq         wait_for_clock_to_stop

    divider         .req                r3
    mov             divider,            #4                          @ divide 19.2MHz clock by 4 = 4.8MHz
    lsl             divider,            #12                         @ shift into integer part of DIV reg
    orr             divider,            divider,    cm_passwd   

    .unreq          cm_pwmctl_read      @ free r2
    cm_pwmdiv_addr  .req                r2
    ldr             cm_pwmdiv_addr,     =BSP_CM_PWMDIV
    str             divider,            [cm_pwmdiv_addr]            @ set the divided clock frequency
    .unreq          cm_pwmdiv_addr      @ free r2

    cm_pwmctl_read  .req                r2
    ldr             cm_pwmctl_read,     [cm_pwmctl_addr]
    orr             cm_pwmctl_read,     #0x11                       @ set clock source to oscillator
    orr             cm_pwmctl_read,     cm_pwmctl_read, cm_passwd
    str             cm_pwmctl_read,     [cm_pwmctl_addr]

    wait_for_clock_to_start:
        ldr         cm_pwmctl_read,     [cm_pwmctl_addr]
        and         cm_pwmctl_read,     cm_pwmctl_read, #0x80       @ busy flag
        cmp         cm_pwmctl_read,     #0                          @ loop until busy flag is high
        beq         wait_for_clock_to_start


    .unreq          cm_pwmctl_addr      @ free r0
    .unreq          cm_passwd           @ free r1
    .unreq          cm_pwmctl_read      @ free r2
    .unreq          divider             @ free r3

    mov             pc,                 lr                          @ return
    


/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch1_Start

Function Description:
    Initialize PWM Channel 1. Resolution is set to 8 bits at 18.75kHz.
    
    Note that only GPIO12 and GPIO18 are available as channel 1 PWM pins on the raspberry pi 3b+ breakout board.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Ch1_Start(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch1_Start
BSP_PWM_Ch1_Start:

    rng1_addr       .req        r0
    ldr             rng1_addr,  =BSP_PWM_RNG1

    rng1_val        .req        r1
    ldr             rng1_val,   =256

    str             rng1_val,   [rng1_addr]         @ set RANGE1 to 256, 8 bits of resolution,
                                                    @ final clock speed for PWM is 18.75KHz (4.8MHz / 256)
    
    .unreq          rng1_addr   @ free r0
    .unreq          rng1_val    @ free r1

    ctl_addr        .req        r0
    ldr             ctl_addr,   =BSP_PWM_CTL

    ctl_read        .req        r1
    ldr             ctl_read,   [ctl_addr]

    mask            .req        r2  
    ldr             mask,       =0x81               @ set MSEN1 and PWEN1 high
    orr             mask,       mask,   ctl_read    @ preserve existing settings
    str             mask,       [ctl_addr]

    .unreq          ctl_addr    @ free r0
    .unreq          ctl_read    @ free r1
    .unreq          mask        @ free r2

    mov             pc,         lr                  @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch2_Start

Function Description:
    Initialize PWM Channel 2. Resolution is set to 8 bits at 18.75kHz.
    
    Note that only GPIO13 and GPIO19 are available as channel 2 PWM pins on the raspberry pi 3b+ breakout board.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Ch2_Start(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch2_Start
BSP_PWM_Ch2_Start:

    rng2_addr       .req        r0
    ldr             rng2_addr,  =BSP_PWM_RNG2

    rng2_val        .req        r1
    ldr             rng2_val,   =256

    str             rng2_val,   [rng2_addr]         @ set RANGE2 to 256, 8 bits of resolution,
                                                    @ final clock speed for PWM is 18.75KHz (4.8MHz / 256)
    
    .unreq          rng2_addr   @ free r0
    .unreq          rng2_val    @ free r1

    ctl_addr        .req        r0
    ldr             ctl_addr,   =BSP_PWM_CTL

    ctl_read        .req        r1
    ldr             ctl_read,   [ctl_addr]

    mask            .req        r2  
    ldr             mask,       =0x81               @ set MSEN2 and PWEN2 high
    lsl             mask,       #8                  @ shift into position
    orr             mask,       mask,   ctl_read    @ preserve existing settings
    str             mask,       [ctl_addr]

    .unreq          ctl_addr    @ free r0
    .unreq          ctl_read    @ free r1
    .unreq          mask        @ free r2

    mov             pc,         lr                  @ return
    
    
    
/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch1_Write

Function Description:
    Writes a value to PWM Channel 1. Range is 8 bits.

Inputs:
    r0: Value to write. Range [0,255]

Returns:
    None

Error Handling:
    Values greater than 255 will be treated as (val % 256)

Equivalent C function signature:
    void BSP_PWM_Ch1_Write(uint32_t value)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch1_Write
BSP_PWM_Ch1_Write:
    pwm_val         .req        r0
    and             pwm_val,    pwm_val,    #0xFF   @ limit to 8 bit range

    ldr r1,         =BSP_PWM_DAT1
    str pwm_val,    [r1]

    .unreq          pwm_val
    
    mov             pc,         lr                  @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch2_Write

Function Description:
    Writes a value to PWM Channel 2. Range is 8 bits.

Inputs:
    r0: Value to write. Range [0,255]

Returns:
    None

Error Handling:
    Values greater than 255 will be treated as (val % 256)

Equivalent C function signature:
    void BSP_PWM_Ch2_Write(uint32_t value)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch2_Write
BSP_PWM_Ch2_Write:
    pwm_val         .req        r0
    and             pwm_val,    pwm_val,    #0xFF   @ limit to 8 bit range

    ldr r1,         =BSP_PWM_DAT2
    str pwm_val,    [r1]

    .unreq          pwm_val
    
    mov             pc,         lr                  @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch1_Set_GPIO12_To_PWM_Mode

Function Description:
    Sets the pin mode of GPIO12 to PWM Channel 1

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Ch1_Set_GPIO12_To_PWM_Mode(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch1_Set_GPIO12_To_PWM_Mode
BSP_PWM_Ch1_Set_GPIO12_To_PWM_Mode:
    push    {lr}

    mov     r0,     #12
    mov     r1,     #0b100          @ gpio12 uses alt mode 0 for PWM
    bl      PSP_GPIO_Set_Pin_Mode

    pop     {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch1_Set_GPIO18_To_PWM_Mode

Function Description:
    Sets the pin mode of GPIO18 to PWM Channel 1

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Ch1_Set_GPIO18_To_PWM_Mode(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch1_Set_GPIO18_To_PWM_Mode
BSP_PWM_Ch1_Set_GPIO18_To_PWM_Mode:
    push    {lr}

    mov     r0,     #18
    mov     r1,     #0b010          @ gpio18 uses alt mode 5 for PWM
    bl      PSP_GPIO_Set_Pin_Mode

    pop     {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch2_Set_GPIO13_To_PWM_Mode

Function Description:
    Sets the pin mode of GPIO13 to PWM Channel 2

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Ch2_Set_GPIO13_To_PWM_Mode(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch2_Set_GPIO13_To_PWM_Mode
BSP_PWM_Ch2_Set_GPIO13_To_PWM_Mode:
    push    {lr}

    mov     r0,     #13
    mov     r1,     #0b100          @ gpio13 uses alt mode 0 for PWM
    bl      PSP_GPIO_Set_Pin_Mode

    pop     {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_PWM_Ch2_Set_GPIO19_To_PWM_Mode

Function Description:
    Sets the pin mode of GPIO19 to PWM Channel 2

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_PWM_Ch2_Set_GPIO19_To_PWM_Mode(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_PWM_Ch2_Set_GPIO19_To_PWM_Mode
BSP_PWM_Ch2_Set_GPIO19_To_PWM_Mode:
    push    {lr}

    mov     r0,     #19
    mov     r1,     #0b010          @ gpio19 uses alt mode 5 for PWM
    bl      PSP_GPIO_Set_Pin_Mode

    pop     {pc}
