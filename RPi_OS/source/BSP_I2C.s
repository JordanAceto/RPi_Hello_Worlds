
/*-----------------------------------------------------------------------------------------------
    BSP_I2C Constants
 -------------------------------------------------------------------------------------------------*/

.equ        BSP_I2C_BASE,       0x3F804000  @ note that board rev 2 uses BSC1 for I2C on pins 2 and 3.
.equ        BSP_I2C_C,          0x3F804000  @ control register
.equ        BSP_I2C_S,          0x3F804004  @ status register
.equ        BSP_I2C_DLEN,       0x3F804008  @ data length register
.equ        BSP_I2C_A,          0x3F80400C  @ slave address register
.equ        BSP_I2C_FIFO,       0x3F804010  @ data FIFO register
.equ        BSP_I2C_DIV,        0x3F804014  @ clock divider register
.equ        BSP_I2C_DEL,        0x3F804018  @ data delay register
.equ        BSP_I2C_CLKT,       0x3F80401C  @ clock stretch timeout register

@ masks for I2C control register
.equ        I2C_C_I2CEN,        0x00008000  @ I2C Enable, 0 = disabled, 1 = enabled
.equ        I2C_C_INTR,         0x00000400  @ Interrupt on RX
.equ        I2C_C_INTT,         0x00000200  @ Interrupt on TX
.equ        I2C_C_INTD,         0x00000100  @ Interrupt on DONE
.equ        I2C_C_ST,           0x00000080  @ Start transfer, 1 = Start a new transfer
.equ        I2C_C_CLEAR_1,      0x00000020  @ Clear FIFO Clear
.equ        I2C_C_CLEAR_2,      0x00000010  @ Clear FIFO Clear
.equ        I2C_C_READ,         0x00000001  @ Read transfer

@ masks for I2C status register
.equ        I2C_S_CLKT,         0x00000200  @ Clock stretch timeout
.equ        I2C_S_ERR,          0x00000100  @ ACK errorI2C_S_ERR
.equ        I2C_S_RXF,          0x00000080  @ RXF FIFO full, 0 = FIFO is not full, 1 = FIFO is full
.equ        I2C_S_TXE,          0x00000040  @ TXE FIFO full, 0 = FIFO is not full, 1 = FIFO is full
.equ        I2C_S_RXD,          0x00000020  @ RXD FIFO contains data
.equ        I2C_S_TXD,          0x00000010  @ TXD FIFO can accept data
.equ        I2C_S_RXR,          0x00000008  @ RXR FIFO needs reading (full)
.equ        I2C_S_TXW,          0x00000004  @ TXW FIFO needs writing (full)
.equ        I2C_S_DONE,         0x00000002  @ Transfer DONE
.equ        I2C_S_TA,           0x00000001  @ Transfer Active

@ pin constants for I2C
.equ        I2C_SDA_PIN,        2
.equ        I2C_SCL_PIN,        3

.equ        ALT_MODE_0,         0b100
.equ        GPIO_INPUT,         0



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_I2C_Start

Function Description:
    Initialize I2C by setting GPIO pins 2 and 3 to alt mode 0.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_I2C_Start(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_I2C_Start
BSP_I2C_Start:

    push        {lr}

    mov         r0,         #I2C_SCL_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #I2C_SDA_PIN
    mov         r1,         #ALT_MODE_0
    bl          PSP_GPIO_Set_Pin_Mode

    pop         {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_I2C_End

Function Description:
    Shut down I2C by setting GPIO pins 2 and 3 to inputs.

Inputs:
    None

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_I2C_End(void)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_I2C_End
BSP_I2C_End:

    push        {lr}

    mov         r0,         #I2C_SCL_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    mov         r0,         #I2C_SDA_PIN
    mov         r1,         #GPIO_INPUT
    bl          PSP_GPIO_Set_Pin_Mode

    pop         {pc}



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_I2C_Set_Clock_Divider

Function Description:
    Sets the clock divider for I2C. This sets the clock speed.

Inputs:
    r0: CDIV. This must be a power of 2. Only the lower 16 bits are used. Odd number are rounded down.

    SCL = core clock / CDIV Wwere core_clk is nominally 150 MHz. If CDIV is set to 0, the divisor is 32768. 
    CDIV is always rounded down to an even number. The default value should result in a 100 kHz I2C clock
    frequency.

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_I2C_Set_Clock_Divider(uint32_t CDIV)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_I2C_Set_Clock_Divider
BSP_I2C_Set_Clock_Divider:
    ldr         r1,         =BSP_I2C_DIV
    str         r0,         [r1]                @ set the divider register to the input parameter divider
    mov         pc,         lr                  @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_I2C_Set_Slave_Address

Function Description:
    Sets the I2C slave device address.

Inputs:
    r0: address, the address of the device to communicate with.

Returns:
    None

Error Handling:
    None

Equivalent C function signature:
    void BSP_I2C_Set_Slave_Address(uint32_t address)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_I2C_Set_Slave_Address
BSP_I2C_Set_Slave_Address:
    ldr         r1,         =BSP_I2C_A
    str         r0,         [r1]                @ set the slave address in the I2C control register
    mov         pc,         lr                  @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    BSP_I2C_Write_Byte

Function Description:
    Writes a single byte to the address in the I2C address register.

Inputs:
    r0: val, the value to write. (note that only the lowest byte of the 32 bit register r0 will be written)

Returns:
    None (this should return some error/ok code in the future that specifies if the transmission was succesful)

Error Handling:
    None

Equivalent C function signature:
    void BSP_I2C_Write_Byte(uint32_t val)

-------------------------------------------------------------------------------------------------*/
.globl  BSP_I2C_Write_Byte
BSP_I2C_Write_Byte:

    val         .req            r0

    @ set data length to 1 byte
    dlen_addr   .req            r1
    ldr         dlen_addr,      =BSP_I2C_DLEN
    mov         r2,             #1
    str         r2,             [dlen_addr]

    .unreq      dlen_addr

    @ populate fifo with the input value
    fifo_addr   .req            r1
    ldr         fifo_addr,      =BSP_I2C_FIFO
    str         val,            [fifo_addr]

    .unreq      fifo_addr

    @ clear status
    s_addr      .req            r1
    ldr         s_addr,         =BSP_I2C_S

    clr_mask    .req            r2

    mov         clr_mask,       #I2C_S_CLKT
    orr         clr_mask,       #I2C_S_ERR
    orr         clr_mask,       #I2C_S_DONE

    str         clr_mask,       [s_addr]

    .unreq      s_addr
    .unreq      clr_mask

    @ enable device and start transfer
    c_addr      .req            r1
    ldr         c_addr,         =BSP_I2C_C

    start_mask  .req            r2

    mov         start_mask,     #I2C_C_I2CEN
    orr         start_mask,     #I2C_C_ST

    str         start_mask,     [c_addr]

    .unreq      c_addr
    .unreq      start_mask

    @ wait for done flag
    s_addr      .req            r1
    ldr         s_addr,         =BSP_I2C_S

    s_read      .req            r2

    wait_for_DONE_flag_to_go_high:
        ldr         s_read,         [s_addr]
        and         s_read,         #I2C_S_DONE
        cmp         s_read,         #0
        beq         wait_for_DONE_flag_to_go_high
    .unreq      s_read

    @ TODO: check acknowledge flag (for returning error code)

    @ TODO: deal with clock stretch timeout (for returning error code)

    @ set done flag in order to clear it and end transmission

    done_mask   .req            r2
    ldr         done_mask,      [s_addr]

    orr         done_mask,      #I2C_S_DONE

    str         done_mask,      [s_addr]

    .unreq      done_mask
    .unreq      s_addr

    @ return
    mov         pc,         lr
