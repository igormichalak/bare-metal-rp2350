#################
### Constants ###
#################

.equ BINARY_INFO_MARKER_START,		0x7188ebf2
.equ BINARY_INFO_MARKER_END,		0xe71aa390
.equ PICOBIN_BLOCK_MARKER_START,	0xffffded3
.equ PICOBIN_BLOCK_MARKER_END,		0xab123579

.equ BOOTROM_ENTRY_OFFSET, 0x7dfc
.equ SRAM_END, 0x20082000

###########################
### Program Info Header ###
### (optional)          ###
###########################

.section .binary_info_header, "a"
binary_info_header:
.word BINARY_INFO_MARKER_START
.word __binary_info_start
.word __binary_info_end
.word address_mapping_table
.word BINARY_INFO_MARKER_END

#################
### IMAGE_DEF ###
#################

.section .embedded_block, "a"
embedded_block:
.word PICOBIN_BLOCK_MARKER_START

### Item 1
.byte	0x42	# Type: Image definition
.byte	0x01	# Size: 1 word
.hword	0x1101	# Flags: EXE | RISC-V | RP2350

### Item 2
.byte	0x44	# Type: Entry Point definition
.byte	0x03	# Size: 3 words
.hword	0x00	# 16-bit pad
.word _reset_handler	# Initial PC address
.word SRAM_END			# Initial SP address

### Item 3
.byte	0xff	# Type: BLOCK_ITEM_LAST
# Other items' size
.hword	(embedded_block_end - embedded_block - 16) / 4
.byte	0x00	# 8-bit pad

### Link (0 == to self)
.word 0

.word PICOBIN_BLOCK_MARKER_END
embedded_block_end:

#############################
### Address Mapping Table ###
#############################

.section .rodata, "a"
address_mapping_table:

# data section
.word __data_load_ptr
.word __data_start
.word __data_end

# scratch_x section
.word __scratch_x_load_ptr
.word __scratch_x_start
.word __scratch_x_end

# scratch_y section
.word __scratch_y_load_ptr
.word __scratch_y_start
.word __scratch_y_end

.word 0 # null terminator

####################
### Program Info ###
### (optional)   ###
####################

.equ BINARY_INFO_RPI_TAG, 0x5052
.equ BINARY_INFO_TYPE_ID_AND_STRING, 6
.equ BINARY_INFO_ID_PROGRAM_NAME, 0x02031c86
.equ BINARY_INFO_ID_PROGRAM_URL, 0x1856239a

.section .binary_info.keep.default, "a"
.word bi_program_name
.word bi_program_url

.section .rodata, "a"

bi_program_name:
.hword	BINARY_INFO_TYPE_ID_AND_STRING
.hword	BINARY_INFO_RPI_TAG
.word	BINARY_INFO_ID_PROGRAM_NAME
.word	program_name

bi_program_url:
.hword	BINARY_INFO_TYPE_ID_AND_STRING
.hword	BINARY_INFO_RPI_TAG
.word	BINARY_INFO_ID_PROGRAM_URL
.word	program_url

program_name:
.asciz	"Bare Metal RP2350"
.p2align 2, 0

program_url:
.asciz "https://github.com/igormichalak/bare-metal-rp2350"
.p2align 2, 0

#######################
### ELF Entry Point ###
#######################

.section .reset, "ax"
.global _entry_point
_entry_point:
	li	t0, BOOTROM_ENTRY_OFFSET
	jr	t0

#####################
### Reset Handler ###
#####################

.section .text
.global _reset_handler
_reset_handler:
# Load data from FLASH to RAM.
	la		t0, address_mapping_table
1:
	lw		a0, 0(t0)
	beqz	a0, 2f
	lw		a1, 4(t0)
	lw		a2, 8(t0)
	call	data_cpy
	addi	t0, t0, 12
	j		1b
2:
# Zero out the .bss section.
	la		a0, __bss_start
	la		a1, __bss_end
	call	bss_fill
# Next 4 calls are optional.
# They set up a faster clock configuration.
	call	init_xosc
	call	init_pll
	call	configure_clk_ref
	call	configure_clk_sys
# Start the system timers,
# assuming that the clk_ref freq is 12 MHz.
	call	start_sys_timers
# Application entry point.
	j		main

data_cpy_loop:
	lw		a3, (a0)
	sw		a3, (a1)
	addi	a0, a0, 4
	addi	a1, a1, 4
data_cpy:
	bltu	a1, a2, data_cpy_loop
	ret

bss_fill_loop:
	sw		x0, (a0)
	addi	a0, a0, 4
bss_fill:
	bltu	a0, a1, bss_fill_loop
	ret

.equ XOSC_FREQ,		(12 * 1000 * 1000)
.equ XOSC_BASE,		0x40048000
.equ XOSC_CTRL,		XOSC_BASE+0x00
.equ XOSC_STATUS,	XOSC_BASE+0x04
.equ XOSC_STARTUP,	XOSC_BASE+0x0c
.equ XOSC_COUNT,	XOSC_BASE+0x10

init_xosc:
	li		a1, XOSC_STARTUP
	lw		a0, (a1)
	li		a2, (~0x00003fff)
	and		a0, a0, a2
	ori		a0, a0, 469 # 10 ms startup delay
	sw		a0, (a1)

	li		a1, XOSC_CTRL
	lw		a0, (a1)
	li		a2, (~0x00ffffff)
	and		a0, a0, a2
	li		a2, 0xfabaa0
	or		a0, a0, a2
	sw		a0, (a1)

	li		a0, XOSC_STATUS
1:
	lw		a1, (a0)
	bexti	a1, a1, 31 # Extract STABLE bit
	beqz	a1, 1b
	ret

.equ ATOMIC_XOR,	0x1000
.equ ATOMIC_SET,	0x2000
.equ ATOMIC_CLEAR,	0x3000

.equ PLL_SYS_BASE,		0x40050000
.equ PLL_SYS_CS,		PLL_SYS_BASE+0x00
.equ PLL_SYS_PWR,		PLL_SYS_BASE+0x04
.equ PLL_SYS_FBDIV_INT,	PLL_SYS_BASE+0x08
.equ PLL_SYS_PRIM,		PLL_SYS_BASE+0x0c

.equ RESETS_BASE,		0x40020000
.equ RESETS_RESET,		RESETS_BASE+0x0
.equ RESETS_RESET_DONE,	RESETS_BASE+0x8

init_pll:
# Bring PLL_SYS out of reset.
	li		a0, (1<<14)
	li		a1, RESETS_RESET+ATOMIC_CLEAR
	sw		a0, (a1)
	li		a1, RESETS_RESET_DONE
1:
	lw		a2, (a1)
	and		a2, a2, a0
	bne		a2, a0, 1b

# Set FBDIV.
	li		a1, PLL_SYS_FBDIV_INT
	lw		a0, (a1)
	li		a2, (~0x00000fff)
	and		a0, a0, a2
	ori		a0, a0, 125 # VCO = 1500 MHz
	sw		a0, (a1)

# Turn on PLL and PLL VCO.
	li		a0, (1<<5)|(1<<0)
	li		a1,	PLL_SYS_PWR+ATOMIC_CLEAR
	sw		a0, (a1)

# Wait for PLL to lock.
	li		a0, PLL_SYS_CS
1:
	lw		a1, (a0)
	bexti	a1, a1, 31 # Extract LOCK bit
	beqz	a1, 1b

# Set up post dividers.
	li		a1, PLL_SYS_PRIM
	lw		a0, (a1)
	li		a2, (~0x00077000)
	and		a0, a0, a2
	li		a2, (5<<16)|(2<<12)
	or		a0, a0, a2
	sw		a0, (a1)

# Turn on PLL post dividers.
	li		a0, (1<<3)
	li		a1,	PLL_SYS_PWR+ATOMIC_CLEAR
	sw		a0, (a1)
	ret

.equ CLOCKS_BASE,				0x40010000
.equ CLOCKS_CLK_REF_CTRL,		CLOCKS_BASE+0x30
.equ CLOCKS_CLK_REF_SELECTED,	CLOCKS_BASE+0x38
.equ CLOCKS_CLK_SYS_CTRL,		CLOCKS_BASE+0x3c
.equ CLOCKS_CLK_SYS_SELECTED,	CLOCKS_BASE+0x44

configure_clk_ref:
# Select XOSC as the source.
	li		a1, CLOCKS_CLK_REF_CTRL
	lw		a0, (a1)
	li		a2, (~0x00000003)
	and		a0, a0, a2
	ori		a0, a0, 0x2
	sw		a0, (a1)

# Wait for XOSC to get selected. 
	li		a0, CLOCKS_CLK_REF_SELECTED
	li		a1, 0b0100
1:
	lw		a2, (a0)
	andi	a2, a2, 0x00f
	bne		a2, a1, 1b
	ret

configure_clk_sys:
# Select AUX as the source.
	li		a0, 1
	li		a1, CLOCKS_CLK_SYS_CTRL+ATOMIC_SET
	sw		a0, (a1)

# Wait for AUX to get selected. 
	li		a0, CLOCKS_CLK_SYS_SELECTED
	li		a1, 0b10
1:
	lw		a2, (a0)
	andi	a2, a2, 0x003
	bne		a2, a1, 1b
	ret

.equ TICKS_BASE,			0x40108000
.equ TICKS_TIMER0_CTRL,		TICKS_BASE+0x18
.equ TICKS_TIMER0_CYCLES,	TICKS_BASE+0x1c
.equ TICKS_TIMER1_CTRL,		TICKS_BASE+0x24
.equ TICKS_TIMER1_CYCLES,	TICKS_BASE+0x28

start_sys_timers:
# Bring timers out of reset.
	li		a0, (1<<24)|(1<<23)
	li		a1, RESETS_RESET+ATOMIC_CLEAR
	sw		a0, (a1)
	li		a1, RESETS_RESET_DONE
1:
	lw		a2, (a1)
	and		a2, a2, a0
	bne		a2, a0, 1b

# Set up timer0 ticker.
	li		a1, TICKS_TIMER0_CYCLES
	lw		a0, (a1)
	ori		a0, a0, 12
	sw		a0, (a1)

	li		a1, TICKS_TIMER0_CTRL+ATOMIC_SET
	li		a0, 1
	sw		a0, (a1)

# Set up timer1 ticker.
	li		a1, TICKS_TIMER1_CYCLES
	lw		a0, (a1)
	ori		a0, a0, 12
	sw		a0, (a1)

	li		a1, TICKS_TIMER1_CTRL+ATOMIC_SET
	li		a0, 1
	sw		a0, (a1)

