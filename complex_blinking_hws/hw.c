
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <stdbool.h>

// pointer to BCM2837 memory map
static volatile uint32_t *gpio;

// valid GPIO pins fall in this range, inclusive
const uint8_t LOWEST_GPIO_PIN = 2;
const uint8_t HIGHEST_GPIO_PIN = 27;

bool isValidPin(const uint8_t pin_num);

const uint8_t LED_PIN = 17; // gpio17

void setup();

typedef enum
{
    INPUT,
    OUTPUT
} pin_mode_t;

typedef enum
{
    LOW,
    HIGH
} digital_write_t;

void pinMode(const uint8_t gpio_pin_num, const pin_mode_t pin_mode);

void digitalWrite(const uint8_t gpio_pin_num, const digital_write_t value);

int main()
{
    setup();

    while(1)
    {
        digitalWrite(LED_PIN, HIGH);
        sleep(1);
        digitalWrite(LED_PIN, LOW);
        sleep(1);
    }

    return 0;
}

void setup()
{
    int fd;

    if ((fd = open("/dev/mem", O_RDWR|O_SYNC)) < 0)
    {
        printf("Unable to open /dev/mem: %s\n", strerror(errno));
        exit(-1);
    }

    // start address for BCM2837 GPIO memory region
    const uint32_t GPFSEL0 = 0x3F200000;
    
    gpio = (uint32_t *)mmap(
        0, 
        getpagesize(), 
        PROT_READ|PROT_WRITE, 
        MAP_SHARED, 
        fd, 
        GPFSEL0
    );

    if (gpio == MAP_FAILED)
    {
        printf("mmap failed: %s\n", strerror(errno));
        exit(-1);
    }

    pinMode(LED_PIN, OUTPUT);
}

void pinMode(const uint8_t gpio_pin_num, const pin_mode_t pin_mode)
{
    if (isValidPin(gpio_pin_num))
    {
        // see datasheet pg 91
        const uint32_t NUM_PINS_PER_GPFSEL_REG = 10;

        const uint32_t GPFSEL_OFFSET = gpio_pin_num / NUM_PINS_PER_GPFSEL_REG;
        
        // each pin gets three bits in its GPFSEL register which set its mode
        const uint32_t PIN_POSITION = (gpio_pin_num % 10) * 3;

        // clear the 3 bits that set the pin mode in GPFSELn
        *(gpio + GPFSEL_OFFSET) &= ~(0b111 << PIN_POSITION);

        if (pin_mode == OUTPUT)
        {
            // set the lsb in GPFSELn to make the pin an output
            *(gpio + GPFSEL_OFFSET) |= (1 << PIN_POSITION);
        }
    }
    else
    {
        // invalid pin, do nothing
    }
}

void digitalWrite(const uint8_t gpio_pin_num, const digital_write_t value)
{
    if (isValidPin(gpio_pin_num)) 
    {
        // see datasheet pg 90
        const uint32_t GPSET0_OFFSET = 7;
        const uint32_t GPCLR0_OFFSET = 10;

        const uint32_t OFFSET = (value == LOW) ? GPCLR0_OFFSET : GPSET0_OFFSET;
    
        *(gpio + OFFSET) = 1 << gpio_pin_num;
    }
    else
    {
        // invalid pin, do nothing
    }
}

bool isValidPin(const uint8_t pin_num)
{
    return LOWEST_GPIO_PIN <= pin_num && pin_num <= HIGHEST_GPIO_PIN;
}