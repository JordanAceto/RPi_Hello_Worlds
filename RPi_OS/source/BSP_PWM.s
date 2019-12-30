
/*-----------------------------------------------------------------------------------------------
    BSP_PWM Constants
 -------------------------------------------------------------------------------------------------*/

 @ PWM Register Addresses
.equ        BSP_PWM_CTL,        0x3F20C000  @ PWM control register
.equ        BSP_PWM_STA,        0x3F20C004  @ PWM status register
.equ        BSP_PWM_DMAC,       0x3F20C008  @ PWM DMA configuration register
.equ        BSP_PWM_RNG1,       0x3F20C010  @ PWM channel 1 range
.equ        BSP_PWM_DAT1,       0x3F20C014  @ PWM channel 1 data
.equ        BSP_PWM_FIF1,       0x3F20C018  @ PWM FIFO input
.equ        BSP_PWM_RNG2,       0x3F20C020  @ PWM channel 2 range
.equ        BSP_PWM_DAT2,       0x3F20C024  @ PWM channel 2 data

.equ        BSP_CM_PWMCTL,      0x3F1010A0  @ PWM clock control register
.equ        BSP_CM_PWMDIV,      0x3F1010A4  @ PWM clock divider register

@ PWM Control Register Masks
.equ        PWM_CTL_MSEN2,      0x00008000  @ Channel 2 M/S Enable
.equ        PWM_CTL_USEF2,      0x00002000  @ Channel 2 Use Fifo
.equ        PWM_CTL_POLA2,      0x00001000  @ Channel 2 Polarity
.equ        PWM_CTL_SBIT2,      0x00000800  @ Channel 2 Silence Bit 
.equ        PWM_CTL_RPT2,       0x00000400  @ Channel 2 Repeat Last Data
.equ        PWM_CTL_MODE2,      0x00000200  @ Channel 2 Mode
.equ        PWM_CTL_PWEN2,      0x00000100  @ Channel 2 Enable 

.equ        PWM_CTL_MSEN1,      0x00000080  @ Channel 1 M/S Enable
.equ        PWM_CTL_CLRF1,      0x00000040  @ Clear Fifo
.equ        PWM_CTL_USEF1,      0x00000020  @ Channel 1 Use Fifo
.equ        PWM_CTL_POLA1,      0x00000010  @ Channel 1 Polarity
.equ        PWM_CTL_SBIT1,      0x00000008  @ Channel 1 Silence Bit
.equ        PWM_CTL_RPTL1,      0x00000004  @ Repeat Last Data
.equ        PWM_CTL_MODE1,      0x00000002  @ Channel 1 Mode
.equ        PWM_CTL_PWEN1,      0x00000001  @ Channel 1 Enable

@ PWM Status Register Masks
.equ        PWM_STA_STA4,       0x00001000  @ Channel 4 State
.equ        PWM_STA_STA3,       0x00000800  @ Channel 3 State
.equ        PWM_STA_STA2,       0x00000400  @ Channel 2 State
.equ        PWM_STA_STA1,       0x00000200  @ Channel 1 State

.equ        PWM_STA_BERR,       0x00000100  @ Bus Error Flag

.equ        PWM_STA_GAPO4,      0x00000080  @ Channel 4 Gap Occurred Flag
.equ        PWM_STA_GAPO3,      0x00000040  @ Channel 3 Gap Occurred Flag
.equ        PWM_STA_GAPO2,      0x00000020  @ Channel 2 Gap Occurred Flag
.equ        PWM_STA_GAPO1,      0x00000010  @ Channel 1 Gap Occurred Flag

.equ        PWM_STA_RERR1,      0x00000008  @ Fifo Read Error Flag
.equ        PWM_STA_WERR1,      0x00000004  @ Fifo Write Error Flag

.equ        PWM_STA_EMPT1,      0x00000002  @ Fifo Empty Flag
.equ        PWM_STA_FULL1,      0x00000001  @ Fifo Full Flag

@ CM PWMCTL register masks
.equ        BSP_CM_PASSWD,      0x5A000000  @ PWM clock password
.equ        CM_PWMCTL_PWD_REG,  0xFF000000  @ password region of CM PWMCLT register
.equ        CM_PWMCTL_ENAB,     0x00000010  @ CM PWMCLT enable
.equ        CM_PWMCTL_BUSY,     0x00000080  @ CM PWMCTL Busy flag
.equ        CM_PWMCTL_USE_OSC,  0x00000011  @ CM PWMCTL use internal oscillator

@ PWM constants
.equ        PWM_DEFAULT_RANGE,  256         @ default PWM range [0, 255]
.equ        PWM_RANGE_MASK,     0xFF        @ used to get (val % PWM_DEFAULT_RANGE)

.equ        PWM_DEFAULT_DIV,    4           @ default clock divider, divide 19.2MHz clock by 4 = 4.8MHz

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
    ldr             mask,               =CM_PWMCTL_PWD_REG
    orr             mask,               #CM_PWMCTL_ENAB
    mvn             mask,               mask                        @ mask saves CM_PWMCTL except pwd and clears ENAB

    and             mask,               cm_pwmctl_read
    orr             mask,               cm_passwd
    str             mask,               [cm_pwmctl_addr]            @ request stop clock (ENAB low)
    .unreq          mask                @ free r3

    wait_for_clock_to_stop:
        ldr         cm_pwmctl_read,     [cm_pwmctl_addr]
        and         cm_pwmctl_read,     #CM_PWMCTL_BUSY
        cmp         cm_pwmctl_read,     #0                          @ loop until busy flag is low
        bne         wait_for_clock_to_stop

    divider         .req                r3
    mov             divider,            #PWM_DEFAULT_DIV            @ divide 19.2MHz clock by 4 = 4.8MHz
    lsl             divider,            #12                         @ shift into integer part of DIV reg
    orr             divider,            cm_passwd   

    .unreq          cm_pwmctl_read      @ free r2
    cm_pwmdiv_addr  .req                r2
    ldr             cm_pwmdiv_addr,     =BSP_CM_PWMDIV
    str             divider,            [cm_pwmdiv_addr]            @ set the divided clock frequency
    .unreq          cm_pwmdiv_addr      @ free r2

    cm_pwmctl_read  .req                r2
    ldr             cm_pwmctl_read,     [cm_pwmctl_addr]
    orr             cm_pwmctl_read,     #CM_PWMCTL_USE_OSC          @ use internal oscillator for clock source
    orr             cm_pwmctl_read,     cm_passwd
    str             cm_pwmctl_read,     [cm_pwmctl_addr]

    wait_for_clock_to_start:
        ldr         cm_pwmctl_read,     [cm_pwmctl_addr]
        and         cm_pwmctl_read,     #CM_PWMCTL_BUSY
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
    ldr             rng1_val,   =PWM_DEFAULT_RANGE

    str             rng1_val,   [rng1_addr]         @ set RANGE1 to 256, 8 bits of resolution,
                                                    @ final clock speed for PWM is 18.75KHz (4.8MHz / 256)
    
    .unreq          rng1_addr   @ free r0
    .unreq          rng1_val    @ free r1

    ctl_addr        .req        r0
    ldr             ctl_addr,   =BSP_PWM_CTL

    ctl_read        .req        r1
    ldr             ctl_read,   [ctl_addr]

    mask            .req        r2  
    ldr             mask,       =PWM_CTL_MSEN1      @ set to mark/space mode and enable
    orr             mask,       #PWM_CTL_PWEN1
    orr             mask,       ctl_read            @ preserve existing settings
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
    ldr             rng2_val,   =PWM_DEFAULT_RANGE

    str             rng2_val,   [rng2_addr]         @ set RANGE2 to 256, 8 bits of resolution,
                                                    @ final clock speed for PWM is 18.75KHz (4.8MHz / 256)
    
    .unreq          rng2_addr   @ free r0
    .unreq          rng2_val    @ free r1

    ctl_addr        .req        r0
    ldr             ctl_addr,   =BSP_PWM_CTL

    ctl_read        .req        r1
    ldr             ctl_read,   [ctl_addr]

    mask            .req        r2  
    ldr             mask,       =PWM_CTL_MSEN2      @ set to mark/space mode and enable
    orr             mask,       #PWM_CTL_PWEN2
    orr             mask,       ctl_read            @ preserve existing settings
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
    and             pwm_val,    #PWM_RANGE_MASK     @ (val % max_val)

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
    and             pwm_val,    #PWM_RANGE_MASK     @ (val % max_val)

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
