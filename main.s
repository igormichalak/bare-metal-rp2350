####################
### Simple Blink ###
####################

.section .text

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

.equ TIMER0_BASE,		0x400b0000
.equ TIMER0_TIMEHR,		TIMER0_BASE+0x08
.equ TIMER0_TIMELR,		TIMER0_BASE+0x0c
.equ TIMER0_TIMERAWH,	TIMER0_BASE+0x24
.equ TIMER0_TIMERAWL,	TIMER0_BASE+0x28

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
	li		a0, 100
	call	wait_ms
	sw		t0, (t2)
	li		a0, 100
	call	wait_ms
	j		loop

# Don't use with durations longer than 1 hour.
wait_ms:
	mv		a2, a0
	li		a0, TIMER0_TIMELR
	li		a1, TIMER0_TIMEHR
	lw		a0, (a0)
	lw		a1, (a1)
	li		a3, 1000
	mul		a2, a2, a3
	add		a0, a0, a2
	sltu	a3, a0, a2
	add		a1, a1, a3
	li		a2, TIMER0_TIMERAWL
	li		a3, TIMER0_TIMERAWH
1:
	lw		a5, (a3)
	blt		a5, a1, 1b
2:
	lw		a5, (a3)
	bne		a5, a1, 3f
	lw		a4, (a2)
	blt		a4, a0, 2b
3:
	ret

