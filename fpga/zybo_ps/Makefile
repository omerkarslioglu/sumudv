# SUMUD-V Zybo Z7-20 PS+DDR bitstream (#2)
ROOT    := $(abspath ../..)
VIVADO  ?= vivado
# Vivado 2025.1 ships xsdb (xsct removed from default PATH)
XSDB    ?= $(shell command -v xsdb 2>/dev/null || command -v xsct 2>/dev/null)
BIT_DIR := bitstream
BIT     := $(BIT_DIR)/sumudv_zybo_ps.bit
FW_DIR  := $(ROOT)/sw/fpga_ddr_memtest
PS7_SRC := vivado/sumudv_zybo_ps.gen/sources_1/bd/design_1/ip/design_1_processing_system7_0_0/ps7_init.tcl

.PHONY: all firmware project bitstream program load-fw clean help

all: bitstream

firmware:
	$(MAKE) -C $(FW_DIR)

project:
	cd $(ROOT) && $(VIVADO) -mode batch -source fpga/zybo_ps/tcl/create_project.tcl \
		-log fpga/zybo_ps/vivado/create_project.log \
		-journal fpga/zybo_ps/vivado/create_project.jou

bitstream: firmware
	@mkdir -p vivado $(BIT_DIR)
	cd $(ROOT) && $(VIVADO) -mode batch -source fpga/zybo_ps/tcl/build_bitstream.tcl \
		-log fpga/zybo_ps/vivado/build_bitstream.log \
		-journal fpga/zybo_ps/vivado/build_bitstream.jou
	@test -f $(BIT) && ls -lh $(BIT)

program:
	@test -f $(BIT) || { echo "Missing $(BIT); run make bitstream"; exit 1; }
	cd $(ROOT) && $(VIVADO) -mode batch -source fpga/zybo_ps/tcl/program_device.tcl \
		-log fpga/zybo_ps/vivado/program.log \
		-journal fpga/zybo_ps/vivado/program.jou

load-fw: firmware
	@test -n "$(XSDB)" || { echo "xsdb/xsct not found — source Vivado settings64.sh"; exit 1; }
	@if [ -f $(PS7_SRC) ] && [ ! -f $(BIT_DIR)/ps7_init.tcl ]; then \
		cp -f $(PS7_SRC) $(BIT_DIR)/ps7_init.tcl; \
	fi
	cd $(ROOT) && $(XSDB) fpga/zybo_ps/tcl/load_fw.tcl

clean:
	rm -rf vivado $(BIT_DIR) *.log *.jou
	$(MAKE) -C $(FW_DIR) clean

help:
	@echo "PS+DDR targets:"
	@echo "  make bitstream  - BD + synth/impl → $(BIT)"
	@echo "  make program    - JTAG program xc7z020 (not ARM DAP)"
	@echo "  make load-fw    - xsdb: ps7_init + load memtest to DDR, cpu_run=1"
	@echo "  UART 115200 on Pmod JB1 — expect 'DDR PASS'"
