
/*-----------------------------------------------------------------------------------------------
    BSP_SPI0 Constants
 -------------------------------------------------------------------------------------------------*/

@ SPI 0 register addresses
.equ        BSP_SPI0_BASE,      0x3F204000  @ 
.equ        BSP_SPI0_CS,        0x3F204000  @ SPI Master Control and Status
.equ        BSP_SPI0_FIFO,      0x3F204004  @ SPI Master TX and RX FIFOs
.equ        BSP_SPI0_CLK,       0x3F204008  @ SPI Master Clock Divider
.equ        BSP_SPI0_DLEN,      0x3F20400C  @ SPI Master Data Length
.equ        BSP_SPI0_LTOH,      0x3F204010  @ SPI LOSSI mode TOH
.equ        BSP_SPI0_DC,        0x3F204014  @ SPI DMA DREQ Controls

@ SPI 0 control register masks
.equ        SPI0_CS_LEN_LONG,   0x02000000  @ Enable Long data word in Lossi mode if DMA_LEN is set
.equ        SPI0_CS_DMA_LEN,    0x01000000  @ Enable DMA mode in Lossi mode
.equ        SPI0_CS_CSPOL2,     0x00800000  @ Chip Select 2 Polarity
.equ        SPI0_CS_CSPOL1,     0x00400000  @ Chip Select 1 Polarity
.equ        SPI0_CS_CSPOL0,     0x00200000  @ Chip Select 0 Polarity
.equ        SPI0_CS_RXF,        0x00100000  @ RXF - RX FIFO Full
.equ        SPI0_CS_RXR,        0x00080000  @ RXR RX FIFO needs Reading ( full)
.equ        SPI0_CS_TXD,        0x00040000  @ TXD TX FIFO can accept Data
.equ        SPI0_CS_RXD,        0x00020000  @ RXD RX FIFO contains Data
.equ        SPI0_CS_DONE,       0x00010000  @ Done transfer Done
.equ        SPI0_CS_TE_EN,      0x00008000  @ Unused
.equ        SPI0_CS_LMONO,      0x00004000  @ Unused
.equ        SPI0_CS_LEN,        0x00002000  @ LEN LoSSI enable
.equ        SPI0_CS_REN,        0x00001000  @ REN Read Enable
.equ        SPI0_CS_ADCS,       0x00000800  @ ADCS Automatically Deassert Chip Select
.equ        SPI0_CS_INTR,       0x00000400  @ INTR Interrupt on RXR
.equ        SPI0_CS_INTD,       0x00000200  @ INTD Interrupt on Done
.equ        SPI0_CS_DMAEN,      0x00000100  @ DMAEN DMA Enable
.equ        SPI0_CS_TA,         0x00000080  @ Transfer Active
.equ        SPI0_CS_CSPOL,      0x00000040  @ Chip Select Polarity
.equ        SPI0_CS_CLEAR1,     0x00000020  @ CLEAR FIFO Clear 1
.equ        SPI0_CS_CLEAR2,     0x00000010  @ CLEAR FIFO Clear 2
.equ        SPI0_CS_CPOL,       0x00000008  @ Clock Polarity
.equ        SPI0_CS_CPHA,       0x00000004  @ Clock Phase
.equ        SPI0_CS_CS1,        0x00000002  @ Chip Select 1
.equ        SPI0_CS_CS2,        0x00000001  @ Chip Select 2

@ SPI 0 GPIO pin numbers
.equ        BSP_SPI0_CE1_PIN,   7
.equ        BSP_SPI0_CE0_PIN,   8
.equ        BSP_SPI0_MISO_PIN,  9
.equ        BSP_SPI0_MOSI_PIN,  10
.equ        BSP_SPI0_CLK_PIN,   11

@ pinmode constants
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
    mov         r1,         #SPI0_CS_CLEAR1
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
    ldr         cs_addr,    =BSP_SPI0_CS        @ get a handle to the control register

    cs_read     .req        r2

    ldr         cs_read,    [cs_addr]
    orr         cs_read,    #SPI0_CS_CLEAR1
    str         cs_read,    [cs_addr]           @ clear fifo rx and tx

    ldr         cs_read,    [cs_addr]
    orr         cs_read,    #SPI0_CS_TA
    str         cs_read,    [cs_addr]           @ set Transfer Active high to enable transfer

    cs_mask     .req        r3
    wait_until_FIFO_can_accept_data:            @ wait for fifo to be able to accept data
        ldr         cs_read,    [cs_addr]
        ldr         cs_mask,    =SPI0_CS_TXD    @ TXD flag goes high when fifo is ready
        and         cs_mask,    cs_read

        cmp         cs_mask,    #0
        beq         wait_until_FIFO_can_accept_data
    .unreq      cs_mask     @ free r3

    fifo_addr   .req        r3
    ldr         fifo_addr,  =BSP_SPI0_FIFO
    str         val,        [fifo_addr]         @ write the input value to the FIFO
    .unreq      fifo_addr   @ free r3

    cs_mask     .req        r3
    wait_until_transfer_is_complete:            @ wait for transfer to complete
        ldr         cs_read,    [cs_addr]
        ldr         cs_mask,    =SPI0_CS_DONE   @ DONE flag goes high when transfer is done
        and         cs_mask,    cs_read

        cmp         cs_mask,    #0
        beq         wait_until_transfer_is_complete
    .unreq      cs_mask     @ free r3

    fifo_addr   .req        r3
    ldr         fifo_addr,  =BSP_SPI0_FIFO
    ldr         val,        [fifo_addr]         @ put return value from the FIFO in r0
    .unreq      fifo_addr   @ free r3

    cs_mask     .req        r3
    ldr         cs_read,    [cs_addr]
    ldr         cs_mask,    =SPI0_CS_TA
    mvn         cs_mask,    cs_mask
    and         cs_mask,    cs_read
    str         cs_mask,    [cs_addr]           @ set Transfer Active low to end the transfer

    .unreq      val
    .unreq      cs_addr
    .unreq      cs_read
    .unreq      cs_mask

    mov         pc,         lr                  @ return
    