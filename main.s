####################
### Simple Blink ###
####################

.section .text

.equ CLOCK_FREQ_KHZ, 12000

.equ ATOMIC_XOR,	0x1000
.equ ATOMIC_SET,	0x2000
.equ ATOMIC_CLEAR,	0x3000

.equ RESETS_BASE,			0x40020000
.equ RESETS_RESET,			RESETS_BASE+0x0
.equ RESETS_RESET_DONE,		RESETS_BASE+0x8

.equ IO_BANK0_BASE,			0x40028000
.equ IO_BANK0_GPIO25_CTRL,	IO_BANK0_BASE+0x0cc

.equ PADS_BANK0_BASE,		0x40038000
.equ PADS_BANK0_GPIO25,		PADS_BANK0_BASE+0x68

.equ SIO_BASE,				0xd0000000
.equ SIO_GPIO_OE_SET,		SIO_BASE+0x038
.equ SIO_GPIO_OUT_SET,		SIO_BASE+0x018
.equ SIO_GPIO_OUT_CLR,		SIO_BASE+0x020

.global main
main:
	li		t0, (1<<6)|(1<<9)
	li		t1, RESETS_RESET+ATOMIC_CLEAR
	sw		t0, (t1)
	li		t1, RESETS_RESET_DONE
1:
	lw		t2, (t1)
	and		t2, t2, t0
	bne		t2, t0, 1b

	li		t0, 0x1f
	li		t1, IO_BANK0_GPIO25_CTRL+ATOMIC_CLEAR
	sw		t0, (t1)

	li		t0, 0x05
	li		t1, IO_BANK0_GPIO25_CTRL+ATOMIC_SET
	sw		t0, (t1)

	li		t0, (1<<25)
	li		t1, SIO_GPIO_OE_SET
	sw		t0, (t1)

	li		t0, (1<<7)|(1<<8)
	li		t1, PADS_BANK0_GPIO25+ATOMIC_CLEAR
	sw		t0, (t1)

	li		t0, (1<<25)
	li		t1, SIO_GPIO_OUT_SET
	li		t2, SIO_GPIO_OUT_CLR
loop:
	sw		t0, (t1)
	li		a0, 200
	call	wait_ms
	sw		t0, (t2)
	li		a0, 200
	call	wait_ms
	j		loop

# It's a very primitive wait function.
# Don't treat it as a reliable timing source.
wait_ms_loop:
	addi	a0, a0, -1
	mv		a2, a1
1:
	addi	a2, a2, -1
	bgtz	a2, 1b
	j		wait_ms_test
wait_ms:
	li		a1, CLOCK_FREQ_KHZ
	li		a2, 2
	divu	a1, a1, a2
wait_ms_test:
	bgtz	a0, wait_ms_loop
	ret

