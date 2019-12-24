
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
    ldr         r0,         =0x3F200000     @ base of GPIO region of memory
    mov         pc,          lr



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

    push        {lr}

    mov         r2,         pin_num     @ move the pin number into r2 so r0 is freed up for the gpio base address
    .unreq      pin_num
    pin_num     .req        r2

    bl          PSP_GPIO_Get_Base_Addr  @ get the base GPIO address, we'll do some math to the pin number to 
    gpfsel_n    .req        r0          @ increment the gpio_base to the correct GPFSEL register

    process_pin$:                       @ GPFSEL regs are grouped by 10 gpio pins each, we need to find which GPFSEL
        cmp     pin_num,    #9          @ reg the pin goes into. first need (pin_num % 10), without costly division.
        subhi   pin_num,    #10         @ move into the next GPFSEL reg for each factor of 10 in the pin_num
        addhi   gpfsel_n,   #4          @ at the end pin_num will contain (pin_num % 10) and gpfsel_n will point
        bhi     process_pin$            @ to the correct GPFSEL register for the pin

    .unreq      pin_num                 @ pin_num is no longer meaningful, we now care about the pin position
    pin_pos     .req        r2          @ which is (pin_num % 10) * 3, this position of the 3 mode bits in GPFSEL_n

    add pin_pos, pin_pos, lsl #1        @ pin_pos *= 3
    lsl         pin_mode,   pin_pos     @ the 3 relevant mode bits are now in position

    mask        .req        r3          @ need to mask out the 3 mode bits so we don't overwrite other pins
    mov         mask,       #0b111
    lsl         mask,       pin_pos     @ shift the 3 bit mask into position
    .unreq      pin_pos                 @ done with pin_pos, free up r2

    mvn         mask,       mask        @ invert the mask, ...001110000... is now ...110001111...

    old_mode    .req        r2          @ the existing pin mode information, we don't want to change other pins
    ldr         old_mode,   [gpfsel_n]
    and         old_mode,   mask        @ clear the 3 bits for this pins mode, leave others untouched
    .unreq      mask

    orr         pin_mode,   old_mode    @ set the 3 bits for this pins mode
    .unreq      old_mode

    str         pin_mode,   [gpfsel_n]  @ set GPFSEL_n bit at the pin position to the pin_mode input paramter  
    .unreq      pin_mode
    .unreq      gpfsel_n 

    pop     {pc}                        @ return from the function



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
    void    PSP_GPIO_Write_Pin(uint32_t pin_num, uint32_t value)

-------------------------------------------------------------------------------------------------*/
.globl  PSP_GPIO_Write_Pin    
PSP_GPIO_Write_Pin:
    pin_num     .req        r0                  @ set up aliases for r0 and r1, pin is the gpio_pin_number, 
    pin_val     .req        r1                  @ val is the value to write, 0 for low and non-zero for high

    cmp         pin_num,    #53                 @ if the pin number is out of range, 
    movhi       pc,         lr                  @ return from the function without doing anything

    mov         r2,         pin_num             @ preserve the gpio pin number in r2
    .unreq      pin_num
    pin_num     .req        r2                  @ update the alias for the gpio pin number

    push        {lr}                            @ preserve the address in the link register on the stack

    bl          Increment_GPIO_Base_If_Pin_GT_31
    gpio_base   .req        r0

    .unreq      pin_num
    pin_pos     .req        r2
    and         pin_pos,    #31                 @ mask out 5 lsb's to get pin position
    
    set_bit     .req        r3
    mov         set_bit,    #1
    lsl         set_bit,    pin_pos
    .unreq      pin_pos                         @ pin_pos = (1 << (pin_num & 31))

    teq         pin_val,    #0                  @ value of 0 means set pin low, anything else means set pin high
    .unreq      pin_val
    streq       set_bit,    [gpio_base, #0x28]  @ set pin position in GPCLR_n to write pin low
    strne       set_bit,    [gpio_base, #0x1C]  @ set pin position in GPSET_n to write pin high
    
    .unreq      set_bit
    .unreq      gpio_base

    pop         {pc}



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
    pin_num     .req        r0                  @ set up aliases for r0  

    cmp         pin_num,    #53                 @ if the pin number is out of range, 
    movhi       r0,         #0                  @ set r0 to zero
    movhi       pc,         lr                  @ return from the function without doing anything else

    mov         r2,         pin_num             @ preserve the gpio pin number in r2
    .unreq      pin_num
    pin_num     .req        r2                  @ update the alias for the gpio pin number

    push        {lr}                            @ preserve the address in the link register on the stack

    bl          Increment_GPIO_Base_If_Pin_GT_31
    gpio_base   .req        r0                  @ base of gpio section, plus 4 if pin num is greater than 31

    gplev_n     .req        r3
    ldr         gplev_n,    [gpio_base, #0x34]  @ read the GPLEV0/1 register
    .unreq      gpio_base

    .unreq      pin_num
    pin_pos     .req        r2
    and         pin_pos,    #31                 @ mask out 5 lsb's to get pin position

    lsr         gplev_n,    pin_pos             @ shift gplev_n reg so that the pin we want to read is in the lsb
    .unreq      pin_pos

    and         gplev_n,    #1                  @ r3 now contains a 0 or a 1, depending on the pin val at GPLEV_n   
    mov         r0,         gplev_n             @ move the return value into r0         
    .unreq      gplev_n

    pop         {pc}                            @ return



/*-----------------------------------------------------------------------------------------------

Function Name:
    Increment_GPIO_Base_If_Pin_GT_31

Function Description:
    GPIO registers such as GPSET, GPCLR, GPLEV, etc. are made of two separate registers, GPxxx0 and GPxxx1

    GPxxx0 handles pins [0, 31], and GPxxx1 handles pins [32, 53]

    This helper function takes in a pin number, and returns a pointer to the GPIO base address, plus an offset of 4
    if the pin falls in the range [32, 53]

Inputs:
    r0: GPIO pin number

Returns:
    Pointer to the base address of the GPIO region of memory plus an optional offset if pin > 31

Error Handling:
    None. It is the responsibility of the caller of this function to provide a valid pin number in r0

Equivalent C function signature:
    void* Increment_GPIO_Base_If_Pin_GT_31(uint32_t pin_num)

-------------------------------------------------------------------------------------------------*/
Increment_GPIO_Base_If_Pin_GT_31:
    pin_num     .req        r0          @ set up aliases for r0 

    push        {lr}

    mov         r2,         pin_num     @ move the pin number into r2 so r0 is freed up for the gpio base address
    .unreq      pin_num
    pin_num     .req        r2

    bl          PSP_GPIO_Get_Base_Addr  
    gpio_base   .req        r0          @ increment the gpio_base to the correct GPFSEL register

    cmpls       pin_num,    #31
    .unreq      pin_num
    addhi       gpio_base,  gpio_base, #4
    .unreq      gpio_base

    pop         {pc}                    @ return with the potentially incremented gpio_base in r0
