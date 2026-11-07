# Minimal Zybo PL bring-up firmware (LED + UART)
CROSS   ?= /opt/riscv/bin/riscv64-unknown-elf-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size

BUILD  := build
COMMON := ../common

CFLAGS  := -march=rv32im_zicsr -mabi=ilp32 -O2 -g -Wall
CFLAGS  += -ffreestanding -fno-builtin -I$(COMMON)
LDFLAGS := -T link_fpga.ld -nostartfiles -specs=nano.specs
LDFLAGS += -Wl,--gc-sections -Wl,-Map=$(BUILD)/fpga_blink.map

.PHONY: all clean

all: $(BUILD)/fpga_blink.elf $(BUILD)/fpga_blink.bin $(BUILD)/fpga_blink.mem
	$(SIZE) $(BUILD)/fpga_blink.elf

$(BUILD)/fpga_blink.elf: $(BUILD)/main.o $(BUILD)/crt0.o $(BUILD)/syscalls.o | $(BUILD)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD)/fpga_blink.bin: $(BUILD)/fpga_blink.elf
	$(OBJCOPY) -O binary $< $@

# Vivado $readmemh image (one 32-bit word per line, little-endian)
$(BUILD)/fpga_blink.mem: $(BUILD)/fpga_blink.bin
	python3 -c "d=open('$<','rb').read(); open('$@','w').write('\\n'.join('{:08x}'.format(int.from_bytes(d[i:i+4].ljust(4,b'\\0'),'little')) for i in range(0,len(d),4))+'\\n')"

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
