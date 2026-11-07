CROSS ?= /opt/riscv/bin/riscv64-unknown-elf-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE := $(CROSS)size

COMMON := common
CFLAGS := -march=rv32im_zicsr -mabi=ilp32 -Os -g -Wall -ffreestanding -fno-builtin
CFLAGS += -I$(COMMON)
LDFLAGS := -T $(COMMON)/link.ld -nostartfiles -ffreestanding -Wl,--gc-sections -lgcc

# Apps + micro-benches (all software lives under sw/)
APPS := fb_demo dhrystone coremark mem_latency branch_torture mul_heavy

.PHONY: all clean doom coremark_eembc $(APPS)

all: $(APPS)

doom:
	$(MAKE) -C doom

coremark_eembc:
	$(MAKE) -C coremark_eembc

define build_app
.PHONY: $(1)
$(1): build/$(1)/$(1).elf build/$(1)/$(1).bin
	$(SIZE) build/$(1)/$(1).elf

build/$(1)/$(1).bin: build/$(1)/$(1).elf
	$(OBJCOPY) -O binary $$< $$@

build/$(1)/crt0.o: $(COMMON)/crt0.S | build/$(1)
	$(CC) $(CFLAGS) -c $$< -o $$@

build/$(1)/syscalls.o: $(COMMON)/syscalls.c | build/$(1)
	$(CC) $(CFLAGS) -c $$< -o $$@

build/$(1):
	mkdir -p $$@
endef

$(foreach a,$(APPS),$(eval $(call build_app,$(a))))

build/fb_demo/fb_demo.elf: build/fb_demo/main.o build/fb_demo/crt0.o build/fb_demo/syscalls.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/fb_demo/main.o: fb_demo/main.c | build/fb_demo
	$(CC) $(CFLAGS) -c $< -o $@

build/dhrystone/dhrystone.elf: build/dhrystone/main.o build/dhrystone/crt0.o build/dhrystone/syscalls.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/dhrystone/main.o: dhrystone/dhry_main.c | build/dhrystone
	$(CC) $(CFLAGS) -c $< -o $@

build/coremark/coremark.elf: build/coremark/main.o build/coremark/crt0.o build/coremark/syscalls.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/coremark/main.o: coremark/core_portme.c | build/coremark
	$(CC) $(CFLAGS) -c $< -o $@

build/mem_latency/mem_latency.elf: build/mem_latency/main.o build/mem_latency/crt0.o build/mem_latency/syscalls.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/mem_latency/main.o: mem_latency/mem_latency.c | build/mem_latency
	$(CC) $(CFLAGS) -c $< -o $@

build/branch_torture/branch_torture.elf: build/branch_torture/main.o build/branch_torture/crt0.o build/branch_torture/syscalls.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/branch_torture/main.o: branch_torture/branch_torture.c | build/branch_torture
	$(CC) $(CFLAGS) -c $< -o $@

build/mul_heavy/mul_heavy.elf: build/mul_heavy/main.o build/mul_heavy/crt0.o build/mul_heavy/syscalls.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
build/mul_heavy/main.o: mul_heavy/mul_heavy.c | build/mul_heavy
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf build
	$(MAKE) -C doom clean
	$(MAKE) -C coremark_eembc clean
