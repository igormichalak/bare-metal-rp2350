# Constants
PROGRAM_NAME = blink
UF2_FAMILY_ID = 0xe48bff5a

# Compiler and linker
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld

# Flags
ASFLAGS = -march=rv32imac_zicsr_zifencei_zba_zbb_zbkb_zbs -g
LDFLAGS = -T memmap.ld

# Files
SOURCES = prelude.s main.s
OBJECTS = $(SOURCES:.s=.o)
TARGET_ELF = $(PROGRAM_NAME).elf
TARGET_UF2 = $(PROGRAM_NAME).uf2

.PHONY: all
all: clean $(TARGET_UF2)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET_ELF): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

$(TARGET_UF2): $(TARGET_ELF)
	picotool uf2 convert $(TARGET_ELF) $(TARGET_UF2) --family $(UF2_FAMILY_ID)

.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET_ELF) $(TARGET_UF2)

