
/*-----------------------------------------------------------------------------------------------
    PSP_GPIO Constants
 -------------------------------------------------------------------------------------------------*/
.equ        PSP_GPIO_BASE_ADDRESS,  0x3F200000  @ base of GPIO

.equ        PSP_GPIO_GPFSEL0,       0x3F200000  @ GPIO Function Select 0
.equ        PSP_GPIO_GPFSEL1,       0x3F200004  @ GPIO Function Select 1
.equ        PSP_GPIO_GPFSEL2,       0x3F200008  @ GPIO Function Select 2
.equ        PSP_GPIO_GPFSEL3,       0x3F20000C  @ GPIO Function Select 3
.equ        PSP_GPIO_GPFSEL4,       0x3F200010  @ GPIO Function Select 4
.equ        PSP_GPIO_GPFSEL5,       0x3F200014  @ GPIO Function Select 5

.equ        PSP_GPIO_GPSET0,        0x3F20001C  @ GPIO Pin Output Set 0
.equ        PSP_GPIO_GPSET1,        0x3F200020  @ GPIO Pin Output Set 1

.equ        PSP_GPIO_GPCLR0,        0x3F200028  @ GPIO Pin Output Clear 0
.equ        PSP_GPIO_GPCLR1,        0x3F20002C  @ GPIO Pin Output Clear 1

.equ        PSP_GPIO_GPLEV0,        0x3F200034  @ GPIO Pin Level 0
.equ        PSP_GPIO_GPLEV1,        0x3F200038  @ GPIO Pin Level 1

.equ        PSP_GPIO_GPEDS0,        0x3F200040  @ GPIO Pin Event Detect Status 0
.equ        PSP_GPIO_GPEDS1,        0x3F200044  @ GPIO Pin Event Detect Status 1

.equ        PSP_GPIO_GPREN0,        0x3F20004C  @ GPIO Pin Rising Edge Detect Enable 0
.equ        PSP_GPIO_GPREN1,        0x3F200050  @ GPIO Pin Rising Edge Detect Enable 1

.equ        PSP_GPIO_GPFEN0,        0x3F200058  @ GPIO Pin Falling Edge Detect Enable 0
.equ        PSP_GPIO_GPFEN1,        0x3F20005C  @ GPIO Pin Falling Edge Detect Enable 1

.equ        PSP_GPIO_GPHEN0,        0x3F200064  @ GPIO Pin High Detect Enable 0
.equ        PSP_GPIO_GPHEN1,        0x3F200068  @ GPIO Pin High Detect Enable 1

.equ        PSP_GPIO_GPLEN0,        0x3F200070  @ GPIO Pin Low Detect Enable 0
.equ        PSP_GPIO_GPLEN1,        0x3F200074  @ GPIO Pin Low Detect Enable 1

.equ        PSP_GPIO_GPAREN0,       0x3F20007C  @ GPIO Pin Async. Rising Edge Detect 0
.equ        PSP_GPIO_GPAREN1,       0x3F200080  @ GPIO Pin Async. Rising Edge Detect 1

.equ        PSP_GPIO_GPAFEN0,       0x3F200088  @ GPIO Pin Async. Falling Edge Detect 0
.equ        PSP_GPIO_GPAFEN1,       0x3F20008C  @ GPIO Pin Async. Falling Edge Detect 1

.equ        PSP_GPIO_GPPUD,         0x3F200094  @ GPIO Pin Pull-up/down Enable

.equ        PSP_GPIO_GPPUDCLK0,     0x3F200098  @ GPIO Pin Pull-up/down Enable Clock 0
.equ        PSP_GPIO_GPPUDCLK1,     0x3F20009C  @ GPIO Pin Pull-up/down Enable Clock 1



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_GPIO_Get_Base_Addr

Function Description:
    Get a pointer to the base address of the GPIO region of memory

Inputs:
    None

Returns:
    pointer to the base address of the GPIO region of memory

Error Handling:
    None

Equivalent C function signature:
    void* PSP_GPIO_Get_Base_Addr(void)

-------------------------------------------------------------------------------------------------*/
.globl PSP_GPIO_Get_Base_Addr
PSP_GPIO_Get_Base_Addr:
    ldr     r0,     =PSP_GPIO_BASE_ADDRESS
    mov     pc,     lr



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_GPIO_Set_Pin_Mode

Function Description:
    Set a GPIO pin mode to Input or Output

Inputs:
    r0: GPIO pin number
    r1: GPIO pin mode, 0 == Input, 1 == Output, 2 to 7 == alternate function, greater than 7 == no effect

Returns:
    None

Error Handling:
    Returns without having any effect if the pin number or pin mode are out of range

Equivalent C function signature:
    void PSP_GPIO_Set_Pin_Mode(uint32_t pin_num, uint32_t pin_mode)

-------------------------------------------------------------------------------------------------*/
.globl PSP_GPIO_Set_Pin_Mode
PSP_GPIO_Set_Pin_Mode:

    pin_num     .req        r0
    pin_mode    .req        r1

    cmp         pin_num,    #53         @ pi has 54 (0 to 53) GPIO pins
    cmpls       pin_mode,   #0b111      @ pin input/output takes up 3 bits: 7 == 0b111
    movhi       pc,         lr          @ exit if pin num or input/output type is out of range

    gpfsel_n    .req        r2
    ldr         gpfsel_n,   =PSP_GPIO_GPFSEL0

    process_pin$:                       @ GPFSEL regs are grouped by 10 gpio pins each, we need to find which GPFSEL
        cmp     pin_num,    #9          @ reg the pin goes into. first need (pin_num % 10), without costly division.
        subhi   pin_num,    #10         @ move into the next GPFSEL reg for each factor of 10 in the pin_num
        addhi   gpfsel_n,   #4          @ at the end pin_num will contain (pin_num % 10) and gpfsel_n will point
        bhi     process_pin$            @ to the correct GPFSEL register for the pin

    .unreq      pin_num                 @ pin_num is no longer meaningful, we now care about the pin position, which is
    pin_pos     .req        r0          @ (pin_num % 10) * 3, this is the position of the 3 mode bits in GPFSEL_n

    add pin_pos, pin_pos, lsl #1        @ pin_pos is already (pin_num % 10) from above, now it is *= 3
    lsl         pin_mode,   pin_pos     @ shift the 3 bits of pin mode information into position

    mask        .req        r3          @ need to mask out the 3 mode bits so we don't overwrite other pin modes
    mov         mask,       #0b111
    lsl         mask,       pin_pos     @ shift the 3 bit mask into position
    .unreq      pin_pos                 @ done with pin_pos, free up r0

    mvn         mask,       mask        @ invert the mask, ...001110000... is now ...110001111...

    old_mode    .req        r0          @ the existing pin mode information, we don't want to change other pins
    ldr         old_mode,   [gpfsel_n]
    and         old_mode,   mask        @ clear the 3 bits for this pins mode, leave others untouched
    .unreq      mask

    orr         pin_mode,   old_mode    @ combine the old mode setting with the 3 bits for the pin we're setting
    .unreq      old_mode
   
    str         pin_mode,   [gpfsel_n]  @ set GPFSEL_n 3 bits at the pin position to the pin_mode input paramter  
    .unreq      pin_mode
    .unreq      gpfsel_n 

    mov         pc,         lr          @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_GPIO_Write_Pin

Function Description:
    Write a GPIO pin high or low

Inputs:
    r0: GPIO pin number
    r1: GPIO pin value, 0 == Low, Non-zero == High

Returns:
    None

Error Handling:
    Returns without having any effect if the pin number is out of range.

    Has no effect if the GPIO pin is not set to Output. However, if the pin is subsequently 
    defined as an output then the bit will be set according to the last set/clear operation.

Equivalent C function signature:
    void PSP_GPIO_Write_Pin(uint32_t pin_num, uint32_t value)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_GPIO_Write_Pin    
PSP_GPIO_Write_Pin:
    pin_num     .req        r0          @ set up aliases for r0 and r1, pin is the gpio_pin_number, 
    pin_val     .req        r1          @ val is the value to write, 0 for low and non-zero for high

    cmp         pin_num,    #53         @ if the pin number is out of range, 
    movhi       pc,         lr          @ return from the function without doing anything

    s_c_reg     .req        r2          @ store the address of GPSET/CLR0, we'll add in the offset later if needed
    teq         pin_val,    #0          @ value of 0 means set pin low, anything else means set pin high
    .unreq      pin_val                 @ free r1

    ldreq       s_c_reg,    =PSP_GPIO_GPCLR0 
    ldrne       s_c_reg,    =PSP_GPIO_GPSET0

    cmp         pin_num,    #31         @ if the pin num goes in GPSET/CLR1 (as opposed to GPSET/CLR0)
    addhi       s_c_reg,    #4          @ increment the GPSET/CLR0 register to GPSET/CLR1

    and         pin_num,    #31         @ mask out 5 lsb's to get pin position in the GPSET/CLRn register
    set_bit     .req        r1
    mov         set_bit,    #1
    lsl         set_bit,    pin_num     @ set_bit = (1 << (pin position))
    .unreq      pin_num                 @ free up r0 

    str         set_bit,    [s_c_reg]   @ write the pin in the calculated register

    .unreq      s_c_reg                 @ free r2
    .unreq      set_bit                 @ free r1

    mov         pc,         lr          @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_GPIO_Read_Pin

Function Description:
    Read a GPIO pin and return 0 if the pin in low and 1 if the pin is high

Inputs:
    r0: GPIO pin number to read

Returns:
    None

Error Handling:
    Returns 0 if the pin number is out of range

Equivalent C function signature:
    uint32_t PSP_GPIO_Read_Pin(uint32_t pin_num)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_GPIO_Read_Pin
PSP_GPIO_Read_Pin:
    pin_num     .req        r0              @ set up aliases for r0  

    cmp         pin_num,    #53             @ if the pin number is out of range, 
    movhi       r0,         #0              @ set r0 to zero
    movhi       pc,         lr              @ return from the function without doing anything else

    gplev_addr  .req        r1
    ldr         gplev_addr, =PSP_GPIO_GPLEV0

    cmp         pin_num,    #31             @ if the pin num is at least 32, its value is in GPLEV1
    addhi       gplev_addr, #4              @ so increment GPLEV0 to GPLEV1

    gplev_n     .req        r2
    ldr         gplev_n,    [gplev_addr]    @ get the contents of the GPLEV_n register
    .unreq      gplev_addr                  @ free r1

    .unreq      pin_num                     @ pin_num is no longer meaningful, we now care about the pin position,
    pin_pos     .req        r0              @ which is pin_num & 31, the 5 lsb's of pin_num
    and         pin_pos,    #31             @ mask out 5 lsb's to get pin position

    lsr         gplev_n,    pin_pos         @ shift gplev_n reg so that the pin we want to read is in the lsb
    .unreq      pin_pos

    and         gplev_n,    #1              @ r2 now contains a 0 or a 1, depending on the pin val at GPLEV_n 
    mov         r0,         gplev_n         @ move the return value into r0         
    .unreq      gplev_n

    mov         pc,         lr              @ return 
