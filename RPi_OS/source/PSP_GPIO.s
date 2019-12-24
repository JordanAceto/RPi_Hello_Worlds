
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
    ldr     r0,     =0x3F200000     @ base of GPIO region of memory
    mov     pc,     lr



/*-----------------------------------------------------------------------------------------------

Function Name:
    PSP_GPIO_Set_Pin_Mode

Function Description:
    Set a GPIO pin mode to Input or Output

Inputs:
    r0: GPIO pin number
    r1: GPIO pin mode, 0 == Input, 1 == Output

Returns:
    None

Error Handling:
    Returns without having any effect if the pin number or pin mode are out of range

Equivalent C function signature:
    void PSP_GPIO_Set_Pin_Mode(uint32_t pin_num, uint32_t pin_mode)

-------------------------------------------------------------------------------------------------*/
.globl PSP_GPIO_Set_Pin_Mode
PSP_GPIO_Set_Pin_Mode:
    cmp     r0,     #53             @ pi has 54 (0 to 53) GPIO pins
    cmpls   r1,     #7              @ pin input/output takes up 3 bits: 7 == 0b111
    movhi   pc,     lr              @ exit if pin num or input/output type is out of range

    push    {lr}
    mov     r2,     r0              @ stash the pin number in r2
    bl      PSP_GPIO_Get_Base_Addr  @ put the pointer to gpio base in r0

    process_pin$:                   @ process the pin number so that it indexes correctly into GPFSEL_n
        cmp     r2,     #9          @ GPFSEL regs are grouped by 10 gpio pins each
        subhi   r2,     #10         @ as long as the gpio pin num in r2 is at least 10, subtract 10 from it and 
        addhi   r0,     #4          @ add 4 to the gpio base address in r0, at the end r2 will contain (gpio_pin % 10)
        bhi     process_pin$        @ and r0 will contain (gpio_base + gpfsel_offset)

    add     r2,     r2,     lsl #1  @ (gpio_pin % 10) * 3, this is the position of the 3 bits for this pin in GPFSEL_n
    lsl     r1,     r2              @ (1 << pin_position), r0 is already incremented to the correct offset
    str     r1,     [r0]            @ set GPFSEL_n bit at the pin position to the pin_mode input paramter
    pop     {pc}                    @ return from the function



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
    Returns without having any effect if the pin number or pin value are out of range.

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
