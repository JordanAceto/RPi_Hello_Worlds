## Notes about the more complex blink programs in this directory:

### The hw.c program is fairly straightforward, you can compile and run this directly on the Raspberry Pi running the Raspbian OS.

### The assembly version requires much more housekeeping. It is basically lesson OK02 from here https://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/, ported to work on the Raspberry Pi 3b+, and using GPIO17 instead of the built in ACT LED. Follow the instructions in the link for how to make and run the program, lessons OK01 and OK02 should cover it. Note that when I was moving my new kernel.img file onto the SD card, I needed to rename both the existing kernel.img file and also the existing kernel7.img file that were already on the card. YMMV based on what is on your SD card.
