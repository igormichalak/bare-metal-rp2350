# Bare Metal RP2350

A minimal GCC setup for writing RISC-V assembly for the Raspberry Pi's RP2350 microcontroller, 
with additional memory section definitions (text, rodata, data, bss, scratch_x, scratch_y) and proper clocking setup code for the Pico 2 
and other similar devboards.

All you need are the following four files:
* `Makefile` --- targets/scripts for compilation and flashing
* `memmap.ld` --- linker script
* `prelude.s` --- binary image definition, entrypoint and startup code
* `main.s` --- application code (a simple blink)

Interrupt and exception handling is still not implemented.
You can find a reference implementation [here](https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/pico_crt0/crt0_riscv.S/).
