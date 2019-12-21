// to compile: $ gcc -o hw hw.c -lwiringPi
// to run:     $ ./hw

#include <stdlib.h>
#include <wiringPi.h>
#include <stdint.h>
#include <stdbool.h>

const uint8_t LED_PIN = 0; // bcm gpio 17

void setup();

int main()
{
    setup();

    const uint16_t DELAY_TIME_MS = 500; // delay time in mSec

    bool led_state = 0;

    while(1)
    {
        digitalWrite(LED_PIN, led_state);
        led_state ^= 1;
        delay(DELAY_TIME_MS);
    }

    return 0;
}

void setup()
{
    if (wiringPiSetup() == -1)
    {
        exit(-1);
    }

    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);
}
