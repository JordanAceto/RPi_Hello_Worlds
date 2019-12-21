import RPi.GPIO as GPIO
import time

# we'll use GPIO.BCM numbering so this pin number will
# be the number printed on the extension pcb that plugs
# into the breadboard, in GPIO.BOARD numbering, this is pin 11
led_pin = 17

def setup():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(led_pin, GPIO.OUT)
    GPIO.output(led_pin, GPIO.LOW)

def loop():
    while True:
        GPIO.output(led_pin, GPIO.HIGH)
        time.sleep(1)
        GPIO.output(led_pin, GPIO.LOW)
        time.sleep(1)

def cleanup():
    GPIO.output(led_pin, GPIO.LOW)
    GPIO.cleanup()

if __name__ == '__main__':
    setup()

    try:
        loop()
    except KeyboardInterrupt:
        cleanup()
