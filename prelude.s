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
	la		t0, address_mapping_table
1:
	lw		a0, 0(t0)
	beqz	a0, 2f
	lw		a1, 4(t0)
	lw		a2, 8(t0)
	addi	s0, t0, 12
	call	data_cpy
	mv		t0, s0
	j		1b
2:
	la		a0, __bss_start
	la		a1, __bss_end
	call	bss_fill
	j		main

data_cpy_loop:
	lw		t0, (a0)
	sw		t0, (a1)
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

