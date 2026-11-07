CROSS   ?= /opt/riscv/bin/riscv64-unknown-elf-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size

BUILD  := build
COMMON := ../common

CFLAGS  := -march=rv32im_zicsr -mabi=ilp32 -O2 -g -Wall
CFLAGS  += -ffreestanding -fno-builtin -I$(COMMON)
LDFLAGS := -T link_fpga.ld -nostartfiles -specs=nano.specs
LDFLAGS += -Wl,--gc-sections -Wl,-Map=$(BUILD)/fpga_ddr_memtest.map

.PHONY: all clean

all: $(BUILD)/fpga_ddr_memtest.elf $(BUILD)/fpga_ddr_memtest.bin
	$(SIZE) $(BUILD)/fpga_ddr_memtest.elf

$(BUILD)/fpga_ddr_memtest.elf: $(BUILD)/main.o $(BUILD)/crt0.o $(BUILD)/syscalls.o | $(BUILD)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD)/fpga_ddr_memtest.bin: $(BUILD)/fpga_ddr_memtest.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/main.o: main.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/crt0.o: $(COMMON)/crt0.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/syscalls.o: $(COMMON)/syscalls.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
