# Build doomgeneric for SUMUD-V (RV32IM bare-metal)
# Upstream: third_party/doomgeneric (git submodule)
CROSS ?= /opt/riscv/bin/riscv64-unknown-elf-
CC    := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE  := $(CROSS)size

DG_ROOT ?= ../../third_party/doomgeneric
DG      := $(DG_ROOT)/doomgeneric
BUILD   := build
COMMON  := ../common

ifeq ($(wildcard $(DG)/doomgeneric.c),)
$(error doomgeneric submodule missing. Run: git submodule update --init --recursive)
endif

CFLAGS := -march=rv32im_zicsr -mabi=ilp32 -O2 -g -Wall
CFLAGS += -ffreestanding -fno-builtin
CFLAGS += -DNORMALUNIX -DCMAP256
CFLAGS += -DDOOMGENERIC_RESX=320 -DDOOMGENERIC_RESY=200
CFLAGS += -I$(DG) -I$(COMMON)
LDFLAGS := -T $(COMMON)/link.ld -nostartfiles -specs=nano.specs
LDFLAGS += -Wl,--gc-sections -Wl,-Map=$(BUILD)/doom.map -lm -lc -lgcc

# Core doomgeneric objects (exclude host platforms)
SRC_DOOM := \
  dummy.c am_map.c doomdef.c doomstat.c dstrings.c d_event.c d_items.c \
  d_iwad.c d_loop.c d_main.c d_mode.c d_net.c f_finale.c f_wipe.c g_game.c \
  hu_lib.c hu_stuff.c info.c i_cdmus.c i_endoom.c i_joystick.c i_scale.c \
  i_sound.c i_system.c i_timer.c memio.c m_argv.c m_bbox.c m_cheat.c \
  m_config.c m_controls.c m_fixed.c m_menu.c m_misc.c m_random.c \
  p_ceilng.c p_doors.c p_enemy.c p_floor.c p_inter.c p_lights.c p_map.c \
  p_maputl.c p_mobj.c p_plats.c p_pspr.c p_saveg.c p_setup.c p_sight.c \
  p_spec.c p_switch.c p_telept.c p_tick.c p_user.c r_bsp.c r_data.c \
  r_draw.c r_main.c r_plane.c r_segs.c r_sky.c r_things.c sha1.c sounds.c \
  statdump.c st_lib.c st_stuff.c s_sound.c tables.c v_video.c wi_stuff.c \
  w_checksum.c w_file.c w_main.c w_wad.c z_zone.c w_file_stdc.c \
  i_input.c i_video.c doomgeneric.c

OBJS := $(addprefix $(BUILD)/,$(SRC_DOOM:.c=.o))
OBJS += $(BUILD)/doomgeneric_sumudv.o
OBJS += $(BUILD)/crt0.o $(BUILD)/syscalls.o

.PHONY: all clean

all: $(BUILD)/doomgeneric.elf $(BUILD)/doomgeneric.bin $(BUILD)/doomgeneric.hex
	$(SIZE) $(BUILD)/doomgeneric.elf

$(BUILD)/doomgeneric.elf: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)

$(BUILD)/doomgeneric.bin: $(BUILD)/doomgeneric.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/doomgeneric.hex: $(BUILD)/doomgeneric.bin
	python3 -c "d=open('$<','rb').read(); open('$@','w').write('\\n'.join('{:08x}'.format(int.from_bytes(d[i:i+4].ljust(4,b'\\0'),'little')) for i in range(0,len(d),4))+'\\n')"

$(BUILD)/%.o: $(DG)/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/doomgeneric_sumudv.o: doomgeneric_sumudv.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/crt0.o: $(COMMON)/crt0.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/syscalls.o: $(COMMON)/syscalls.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
