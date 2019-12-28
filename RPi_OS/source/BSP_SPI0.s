
/*-----------------------------------------------------------------------------------------------
    BSP_SPI0 Constants
 -------------------------------------------------------------------------------------------------*/


.equ        BSP_SPI0_BASE,      0x3F204000
.equ        BSP_SPI0_CS,        0x3F204000
.equ        BSP_SPI0_FIFO,      0x3F204004
.equ        BSP_SPI0_CLK,       0x3F204008
.equ        BSP_SPI0_DLEN,      0x3F20400C
.equ        BSP_SPI0_LTOH,      0x3F204010
.equ        BSP_SPI0_DC,        0x3F204014

.equ        CLEAR_FIFO_TX_RX,   0x00000030
.equ        CS_TA_BIT,          0x00000080
.equ        CS_TXD_BIT,         0x00040000
.equ        CS_DONE_BIT,        0x00010000

.equ        BSP_SPI0_CE1_PIN,   7
.equ        BSP_SPI0_CE0_PIN,   8
.equ        BSP_SPI0_MISO_PIN,  9
.equ        BSP_SPI0_MOSI_PIN,  10
.equ        BSP_SPI0_CLK_PIN,   11

.equ        ALT_MODE_0,         0b100
.equ        GPIO_INPUT,         0


/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_SPI0_Start

Function Description:
    Initialize SPI0 by setting GPIO pins 7 through 11 to alt mode 0, zeroing the SPI0 status
    and control register, and clearing the SPI0 Rx FIFO and Tx FIFO buffers.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_SPI0_Start(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_SPI0_Start
BSP_SPI0_Start:

    push        {lr}

    mov         r0,         #BSP_SPI0_CE1_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_CE0_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_MISO_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_MOSI_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_CLK_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    ldr         r0,         =BSP_SPI0_CS
    mov         r1,         #0
    str         r1,         [r0]                @ zero out spi status reg
    mov         r1,         #CLEAR_FIFO_TX_RX
    str         r1,         [r0]                @ clear fifo rx and tx

    pop         {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_SPI0_End

Function Description:
    Shuts down SPI0 by setting GPIO pins 7 through 11 to inputs.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_SPI0_End(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_SPI0_End
BSP_SPI0_End:

    push        {lr}

    mov         r0,         #BSP_SPI0_CE1_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_CE0_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_MISO_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_MOSI_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #BSP_SPI0_CLK_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    pop         {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_SPI0_Set_Clock_Divider

Function Description:
    Sets the clock divider for SPI0. This sets the speed for the SPI0 clock.

    If this function is never called, the divider will default to 65536.

Inputs:
    r0: divider. This must be a power of 2. Only the lower 16 bits are used. Odd number are rounded down.
    
    The following are the the valid dividers: (note that the fastest three speeds may not work, experimentation needed)

       div    speed
        2    125.0 MHz
        4     62.5 MHz
        8     31.2 MHz
       16     15.6 MHz
       32      7.8 MHz
       64      3.9 MHz
      128     1953 kHz
      256      976 kHz
      512      488 kHz
     1024      244 kHz
     2048      122 kHz
     4096       61 kHz
     8192     30.5 kHz
    16384     15.2 kHz
    32768     7629 Hz

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_SPI0_Set_Clock_Divider(uint32_t divider)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_SPI0_Set_Clock_Divider
BSP_SPI0_Set_Clock_Divider:
    ldr         r1,         =BSP_SPI0_CLK
    str         r0,         [r1]                @ set the clock register to the input parameter divider
    mov         pc,         lr                  @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_SPI0_Transfer_Byte

Function Description:
    Write and read a single byte via SPI0. Uses Polled transfer as described in section 10.6.1 of the datasheet.

Inputs:
    r0: val the byte to write via SPI0. (passed in a 32 bit register, but only the first byte is written)

Returns:
    r0: the value read by SPI0. (returned into a 32 bit register, but only the lowest byte will be read)

Error Handling:
    None

Equivalent C function signature:
    uint32_t BSP_SPI0_Transfer_Byte(uint32_t val)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_SPI0_Transfer_Byte
BSP_SPI0_Transfer_Byte:
    val         .req        r0

    cs_addr     .req        r1
    ldr         cs_addr,    =BSP_SPI0_CS

    cs_read     .req        r2

    ldr         cs_read,    [cs_addr]
    orr         cs_read,    #CLEAR_FIFO_TX_RX
    str         cs_read,    [cs_addr]           @ clear fifo rx and tx

    ldr         cs_read,    [cs_addr]
    orr         cs_read,    #CS_TA_BIT
    str         cs_read,    [cs_addr]           @ set TA high to enable transfer

    cs_mask     .req        r3
    wait_for_TXD_to_go_high:
        ldr         cs_read,    [cs_addr]
        ldr         cs_mask,    =CS_TXD_BIT
        and         cs_mask,    cs_read

        cmp         cs_mask,    #0
        beq         wait_for_TXD_to_go_high
    .unreq      cs_mask     @ free r3

    fifo_addr   .req        r3
    ldr         fifo_addr,  =BSP_SPI0_FIFO
    str         val,        [fifo_addr]         @ write the input value to the FIFO
    .unreq      fifo_addr   @ free r3

    cs_mask     .req        r3
    wait_for_DONE_to_go_high:
        ldr         cs_read,    [cs_addr]
        ldr         cs_mask,    =CS_DONE_BIT
        and         cs_mask,    cs_read

        cmp         cs_mask,    #0
        beq         wait_for_DONE_to_go_high
    .unreq      cs_mask     @ free r3

    fifo_addr   .req        r3
    ldr         fifo_addr,  =BSP_SPI0_FIFO
    ldr         val,        [fifo_addr]         @ put return value from the FIFO in r0
    .unreq      fifo_addr   @ free r3

    cs_mask     .req        r3
    ldr         cs_read,    [cs_addr]
    ldr         cs_mask,    =CS_TA_BIT
    mvn         cs_mask,    cs_mask
    and         cs_mask,    cs_read
    str         cs_mask,    [cs_addr]           @ set TA low to end the transfer

    .unreq      val
    .unreq      cs_addr
    .unreq      cs_read
    .unreq      cs_mask

    mov         pc,         lr                  @ return
    