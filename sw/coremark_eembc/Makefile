# SUMUD-V CoreMark port — upstream sources live in third_party/coremark (submodule).
CROSS ?= /opt/riscv/bin/riscv64-unknown-elf-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE := $(CROSS)size

COMMON := ../common
BUILD := build
COREMARK ?= ../../third_party/coremark

# ITERATIONS: small for RTL sim; raise for FPGA (≥10s wall time for official claims)
ITERATIONS ?= 4
CPU_HZ ?= 50000000

ifeq ($(wildcard $(COREMARK)/core_main.c),)
$(error CoreMark submodule missing. Run: git submodule update --init --recursive)
endif

CFLAGS := -march=rv32im_zicsr -mabi=ilp32 -O2 -g -Wall
CFLAGS += -ffreestanding -fno-builtin
CFLAGS += -I. -I$(COREMARK) -I$(COMMON)
CFLAGS += -DPERFORMANCE_RUN=1 -DITERATIONS=$(ITERATIONS)
CFLAGS += -DCPU_HZ=$(CPU_HZ)
CFLAGS += -DFLAGS_STR=\"-O2\"
CFLAGS += -DMAIN_HAS_NOARGC=1
# Enable for RTL/FPGA UART; omit for Spike (MMIO traps)
CFLAGS += -DSUMUDV_HAS_UART

LDFLAGS := -T link_coremark.ld -nostartfiles -specs=nano.specs
LDFLAGS += -Wl,--gc-sections -lc -lgcc

# Upstream (submodule) + local port
UPSTREAM_SRCS := core_list_join.c core_main.c core_matrix.c core_state.c core_util.c
PORT_SRCS := core_portme.c

OBJS := $(addprefix $(BUILD)/,$(UPSTREAM_SRCS:.c=.o) $(PORT_SRCS:.c=.o))
OBJS += $(BUILD)/ee_printf.o
OBJS += $(BUILD)/crt0.o $(BUILD)/syscalls.o

.PHONY: all clean

all: $(BUILD)/coremark.elf $(BUILD)/coremark.bin $(BUILD)/coremark.hex
	$(SIZE) $(BUILD)/coremark.elf

$(BUILD)/coremark.elf: $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD)/coremark.bin: $(BUILD)/coremark.elf
	$(OBJCOPY) -O binary $< $@

# Verilog $readmemh: image only (exclude Spike .tohost hole)
$(BUILD)/coremark.hex: $(BUILD)/coremark.elf
	$(OBJCOPY) -O binary --remove-section=.tohost $< $(BUILD)/coremark.img.bin
	python3 -c "d=open('$(BUILD)/coremark.img.bin','rb').read(); \
open('$(BUILD)/coremark.hex','w').write('\n'.join('{:08x}'.format(int.from_bytes(d[i:i+4].ljust(4,b'\\0'),'little')) for i in range(0,len(d),4))+'\n')"

$(BUILD)/%.o: $(COREMARK)/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

# barebones ee_printf requires uart_send_char() (in core_portme.c). Drop the
# placeholder definition (and its #error) so the submodule file stays pristine.
$(BUILD)/ee_printf.o: $(COREMARK)/barebones/ee_printf.c | $(BUILD)
	python3 -c "import re,sys; t=open(sys.argv[1]).read(); t=re.sub(r'\nvoid\nuart_send_char\(char c\)\n\{.*?\n\}','\nvoid uart_send_char(char c);\n',t,count=1,flags=re.S); sys.stdout.write(t)" $< \
	  | $(CC) $(CFLAGS) -c -x c - -o $@

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/crt0.o: $(COMMON)/crt0.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/syscalls.o: $(COMMON)/syscalls.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
