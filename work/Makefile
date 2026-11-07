# Makefile for SUMUD-V RISC-V Core (ModelSim/Questa)

ROOT_DIR := $(shell pwd)/..
RTL_DIR  := $(ROOT_DIR)/rtl
DV_DIR   := $(ROOT_DIR)/dv
PKG_DIR  := $(ROOT_DIR)/pkg
INC_DIR  := $(ROOT_DIR)/includes
WORK_DIR := $(ROOT_DIR)/work

VLIB := vlib
VLOG := vlog
VSIM := vsim
WORK_LIB := work

VLOG_FLAGS := -sv
VLOG_FLAGS += +incdir+$(INC_DIR)
VLOG_FLAGS += -work $(WORK_LIB)
VLOG_FLAGS += -timescale=1ns/100ps

VSIM_FLAGS := -voptargs=+acc
VSIM_FLAGS += -do "run -all; quit -f"
VSIM_FLAGS += -c

GUI ?= 0
ifeq ($(GUI), 1)
  VSIM_FLAGS := -voptargs=+acc
  VSIM_FLAGS += -do "add wave -recursive /*; run -all"
endif

TB_TOP ?= tb_top

.PHONY: all create_lib compile sim sim-cache gui clean help bench-score sw

all: clean compile sim

create_lib:
	@echo "Creating work library..."
	@$(VLIB) $(WORK_LIB)

compile: create_lib
	@echo "Compiling design from files.f ..."
	@$(VLOG) $(VLOG_FLAGS) -f $(WORK_DIR)/files.f
	@echo "Compilation complete!"

compile-cache: create_lib
	@$(VLOG) $(VLOG_FLAGS) -f $(WORK_DIR)/files.f
	@$(VLOG) $(VLOG_FLAGS) $(DV_DIR)/tb_cache.sv

sim:
	@echo "Running simulation ($(TB_TOP))..."
	@$(VSIM) $(VSIM_FLAGS) $(WORK_LIB).$(TB_TOP)

sim-cache: compile-cache
	@$(MAKE) TB_TOP=tb_cache sim

.PHONY: sim-coremark compile-coremark sim-coremark-vlt
ITERATIONS ?= 4

# Prefer local installs (no sudo): oss-cad-suite, then extracted Debian package.
OSSCAD ?= $(HOME)/tools/oss-cad-suite
VLTDEB_ROOT ?= $(HOME)/tools/verilator-deb/usr/share/verilator
export PATH := $(OSSCAD)/bin:$(HOME)/tools/verilator-deb/usr/bin:$(PATH)
ifneq ($(wildcard $(OSSCAD)/bin/verilator),)
  export VERILATOR_ROOT := $(OSSCAD)/share/verilator
else ifneq ($(wildcard $(VLTDEB_ROOT)/include/verilated_std.sv),)
  export VERILATOR_ROOT := $(VLTDEB_ROOT)
endif
VERILATOR ?= verilator
VERILATOR_FLAGS := -sv --binary --timing -Wall -Wno-fatal
VERILATOR_FLAGS += +incdir+$(INC_DIR)
VERILATOR_FLAGS += -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM
VERILATOR_FLAGS += -Wno-UNDRIVEN -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND
VERILATOR_FLAGS += -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET
VERILATOR_FLAGS += -Wno-BLKANDNBLK -Wno-INITIALDLY
VERILATOR_FLAGS += -Wno-TIMESCALEMOD -Wno-BLKSEQ
VERILATOR_FLAGS += -Wno-BLKLOOPINIT -Wno-VARHIDDEN
VERILATOR_FLAGS += -CFLAGS -O3
VERILATOR_FLAGS += --public
VERILATOR_OBJ_DIR := $(WORK_DIR)/obj_dir_coremark
VERILATOR_DOOM_DIR := $(WORK_DIR)/obj_dir_doom
VERILATOR_CACHE_DIR := $(WORK_DIR)/obj_dir_cache
VERILATOR_TB_DIR := $(WORK_DIR)/obj_dir_tb
VERILATOR_CM_CACHED_DIR := $(WORK_DIR)/obj_dir_coremark_cached

compile-coremark: create_lib
	@$(MAKE) -C $(ROOT_DIR)/sw/coremark_eembc ITERATIONS=$(ITERATIONS)
	@$(VLOG) $(VLOG_FLAGS) -f $(WORK_DIR)/files.f
	@$(VLOG) $(VLOG_FLAGS) $(DV_DIR)/tb_coremark.sv

sim-coremark: compile-coremark
	@$(MAKE) TB_TOP=tb_coremark sim

.PHONY: sim-tb-vlt sim-cache-vlt sim-coremark-vlt sim-coremark-cached-vlt sim-doom-vlt

# Verilator: pipeline smoke (MUL/DIV, forwarding, load-use)
sim-tb-vlt:
	@command -v $(VERILATOR) >/dev/null || { echo "verilator not found; install under $(OSSCAD) or verilator-deb"; exit 1; }
	@mkdir -p $(VERILATOR_TB_DIR)
	@cd $(WORK_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module tb_top \
		-Mdir $(VERILATOR_TB_DIR) \
		-f $(WORK_DIR)/files_tb_vlt.f \
		-o Vtb_top
	@cd $(WORK_DIR) && $(VERILATOR_TB_DIR)/Vtb_top

# Verilator: 32 B line-fill I$/D$ + write-back + uncached FB vs DDR latency
sim-cache-vlt:
	@command -v $(VERILATOR) >/dev/null || { echo "verilator not found; install under $(OSSCAD) or verilator-deb"; exit 1; }
	@mkdir -p $(VERILATOR_CACHE_DIR)
	@cd $(WORK_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module tb_cache \
		-Mdir $(VERILATOR_CACHE_DIR) \
		-f $(WORK_DIR)/files_cache_vlt.f \
		-o Vtb_cache
	@cd $(WORK_DIR) && $(VERILATOR_CACHE_DIR)/Vtb_cache

# Verilator: ideal-BRAM CoreMark (DPI memory model, cache bypass / bare core)
sim-coremark-vlt:
	@command -v $(VERILATOR) >/dev/null || { echo "verilator not found; install under $(OSSCAD) or verilator-deb"; exit 1; }
	@$(MAKE) -C $(ROOT_DIR)/sw/coremark_eembc ITERATIONS=$(ITERATIONS)
	@mkdir -p $(VERILATOR_OBJ_DIR)
	@cd $(WORK_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module tb_coremark \
		-Mdir $(VERILATOR_OBJ_DIR) \
		-f $(WORK_DIR)/files_coremark_vlt.f \
		$(DV_DIR)/tb_coremark_mem.cpp \
		-o Vtb_coremark
	@cd $(WORK_DIR) && $(VERILATOR_OBJ_DIR)/Vtb_coremark

# Verilator: CoreMark through L1 I$/D$ + store buffer
sim-coremark-cached-vlt:
	@command -v $(VERILATOR) >/dev/null || { echo "verilator not found; install under $(OSSCAD) or verilator-deb"; exit 1; }
	@$(MAKE) -C $(ROOT_DIR)/sw/coremark_eembc ITERATIONS=$(ITERATIONS)
	@mkdir -p $(VERILATOR_CM_CACHED_DIR)
	@cd $(WORK_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module tb_coremark_cached \
		-Mdir $(VERILATOR_CM_CACHED_DIR) \
		-f $(WORK_DIR)/files_coremark_cached_vlt.f \
		$(DV_DIR)/tb_coremark_mem.cpp \
		-o Vtb_coremark_cached
	@cd $(WORK_DIR) && $(VERILATOR_CM_CACHED_DIR)/Vtb_coremark_cached

sim-doom-vlt:
	@command -v $(VERILATOR) >/dev/null || { echo "verilator not found; install under $(OSSCAD) or verilator-deb"; exit 1; }
	@$(MAKE) -C $(ROOT_DIR)/sw/doom
	@mkdir -p $(VERILATOR_DOOM_DIR)
	@cd $(WORK_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module tb_doom \
		-Mdir $(VERILATOR_DOOM_DIR) \
		-f $(WORK_DIR)/files_doom_vlt.f \
		$(DV_DIR)/tb_coremark_mem.cpp \
		-o Vtb_doom
	@cd $(WORK_DIR) && $(VERILATOR_DOOM_DIR)/Vtb_doom

gui:
	@$(MAKE) GUI=1 sim

sw:
	@$(MAKE) -C $(ROOT_DIR)/sw all

bench-score:
	@python3 $(ROOT_DIR)/bench/scripts/score.py $(ROOT_DIR)/bench/results/example.json

clean:
	@echo "Cleaning work directory..."
	@rm -rf $(WORK_LIB) transcript vsim.wlf *.log $(VERILATOR_OBJ_DIR) $(VERILATOR_DOOM_DIR) \
		$(VERILATOR_CACHE_DIR) $(VERILATOR_TB_DIR) $(VERILATOR_CM_CACHED_DIR)
	@echo "Clean complete!"

help:
	@echo "Targets: all, compile, sim, gui, clean, bench-score, sim-coremark, sim-coremark-vlt"
	@echo "  make / make all          - clean + compile + sim"
	@echo "  make gui                 - simulation with waves"
	@echo "  make sim-tb-vlt          - Verilator pipeline smoke (MUL/DIV)"
	@echo "  make sim-cache-vlt       - Verilator L1 32 B / WB+WA vs DDR"
	@echo "  make sim-coremark        - ModelSim CoreMark (ideal BRAM)"
	@echo "  make sim-coremark-vlt    - Verilator CoreMark (ideal BRAM)"
	@echo "  make sim-coremark-cached-vlt - Verilator CoreMark (L1 on)"
	@echo "  make sim-doom-vlt        - Verilator DOOM init (cached, no HDMI)"
	@echo "  ITERATIONS=N             - CoreMark iterations (default 4)"
