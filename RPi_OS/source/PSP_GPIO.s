
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
    pin     .req    r0              @ set up aliases for r0 and r1, pin is the gpio_pin_number, 
    val     .req    r1              @ val is the value to write, 0 for low and non-zero for high

    cmp     pin,    #53             @ if the pin number is out of range, 
    movhi   pc,     lr              @ return from the function without doing anything

    push    {lr}                    @ preserve the address in the link register on the stack
    mov     r2,     pin             @ preserve the gpio pin number in r2
    .unreq  pin
    pin     .req    r2              @ update the alias for the gpio pin number

    bl      PSP_GPIO_Get_Base_Addr  @ get a pointer to the gpio base address, put it in r0
    addr    .req    r0              @ alias for gpio pointer

    pins    .req    r3              @ need to find GPSET_n or GPCLR_n, 
    lsr     pins,   pin,    #5      @ pins = (pin_num // 32)
    lsl     pins,   #2              @ pins *= 4
    add     addr,   pins            @ if pin_num >= 32, add 4 to gpio_base to move GPSET0 / GPCLR0 to GPSET/CLR1
    .unreq  pins

    and     pin,    #31             @ mask out 5 lsbs
    setBit  .req    r3
    mov     setBit, #1
    lsl     setBit, pin             @ setBit = (1 << pin_num)
    .unreq  pin

    teq     val,    #0              @ value of 0 means set pin low, anything else means set pin high
    .unreq  val
    streq   setBit, [addr, #0x28]   @ set pin position in GPCLR_n to write pin low
    strne   setBit, [addr, #0x1C]   @ set pin position in GPSET_n to write pin high
    .unreq  setBit
    .unreq  addr
    pop     {pc}
