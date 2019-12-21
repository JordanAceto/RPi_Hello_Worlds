#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>

static volatile uint32_t *gpio;

void setup();

int main()
{
    setup();

    while(1)
    {
        // set gpio17 high
        *(gpio + 7) = 1 << 17;
        sleep(1);
        // set gpio17 low
        *(gpio + 10) = 1 << 17;
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

    const uint32_t OFFSET = 0x3F200000;

    gpio = (uint32_t *)mmap(0, getpagesize(), PROT_READ|PROT_WRITE, MAP_SHARED, fd, OFFSET);

    if (gpio == MAP_FAILED)
    {
        printf("mmap failed: %s\n", strerror(errno));
        exit(-1);
    }

    // set gpio17 as output
    *(gpio + 1) = (*(gpio + 1) & ~(7 << 21)) | (1 << 21);
}
