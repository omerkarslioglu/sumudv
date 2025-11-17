# Makefile for RISC-V Core Simulation using ModelSim

# Project directories
ROOT_DIR := $(shell pwd)/..
RTL_DIR := $(ROOT_DIR)/rtl
DV_DIR := $(ROOT_DIR)/dv
PKG_DIR := $(ROOT_DIR)/pkg
INC_DIR := $(ROOT_DIR)/includes
WORK_DIR := $(ROOT_DIR)/work

# ModelSim settings
VLIB := vlib
VLOG := vlog
VSIM := vsim
WORK_LIB := work

# Compilation flags
VLOG_FLAGS := -sv
VLOG_FLAGS += +incdir+$(INC_DIR)
VLOG_FLAGS += -work $(WORK_LIB)
VLOG_FLAGS += -timescale=1ns/1ps

# Simulation flags
VSIM_FLAGS := -voptargs=+acc
VSIM_FLAGS += -do "run -all; quit -f"
VSIM_FLAGS += -c

# GUI mode flag (set GUI=1 for GUI mode)
GUI ?= 0
ifeq ($(GUI), 1)
    VSIM_FLAGS := -voptargs=+acc
    VSIM_FLAGS += -do "add wave -recursive /*; run -all"
endif

# Source files (in compilation order)
PKG_FILES := $(PKG_DIR)/core_pkg.sv
RTL_FILES := $(RTL_DIR)/decoder.sv \
             $(RTL_DIR)/core.sv
DV_FILES := $(DV_DIR)/tb_top.sv

# Top-level testbench module
TB_TOP := tb_top

# Default target
.PHONY: all
all: clean compile sim

# Create work library
.PHONY: create_lib
create_lib:
	@echo "Creating work library..."
	@$(VLIB) $(WORK_LIB)

# Compile all source files
.PHONY: compile
compile: create_lib
	@echo "Compiling package files..."
	@$(VLOG) $(VLOG_FLAGS) $(PKG_FILES)
	@echo "Compiling RTL files..."
	@$(VLOG) $(VLOG_FLAGS) $(RTL_FILES)
	@echo "Compiling testbench files..."
	@$(VLOG) $(VLOG_FLAGS) $(DV_FILES)
	@echo "Compilation complete!"

# Run simulation
.PHONY: sim
sim:
	@echo "Running simulation..."
	@$(VSIM) $(VSIM_FLAGS) $(WORK_LIB).$(TB_TOP)

# Run simulation in GUI mode
.PHONY: gui
gui:
	@$(MAKE) GUI=0 sim

# Clean generated files
.PHONY: clean
clean:
	@echo "Cleaning work directory..."
	@rm -rf $(WORK_LIB)
	@rm -rf transcript
	@rm -rf vsim.wlf
	@rm -rf *.log
	@echo "Clean complete!"

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all        - Clean, compile, and run simulation (default)"
	@echo "  compile    - Compile all source files"
	@echo "  sim        - Run simulation in console mode"
	@echo "  gui        - Run simulation in GUI mode"
	@echo "  clean      - Remove generated files"
	@echo "  help       - Display this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make              # Run full flow (clean + compile + simulate)"
	@echo "  make compile      # Only compile"
	@echo "  make gui          # Run simulation with GUI"
	@echo "  make clean        # Clean generated files"