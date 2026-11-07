# SUMUD-V Zybo Z7-20 bitstream flow (Vivado 2020.1+ / 2025.1)
#
#   make bitstream   # firmware + create project + synth/impl/bit
#   make program     # JTAG program bitstream/*.bit

ROOT      := $(abspath ../..)
VIVADO   ?= vivado
JOBS     ?= 8
FW_DIR   := $(ROOT)/sw/fpga_blink
BIT_DIR  := bitstream
BIT      := $(BIT_DIR)/sumudv_zybo.bit

.PHONY: all firmware project bitstream program clean help

all: bitstream

firmware:
	$(MAKE) -C $(FW_DIR)
	@mkdir -p vivado
	@cp -f $(FW_DIR)/build/fpga_blink.mem vivado/firmware.mem

project: firmware
	cd $(ROOT) && $(VIVADO) -mode batch -source fpga/zybo/tcl/create_project.tcl \
		-log fpga/zybo/vivado/create_project.log \
		-journal fpga/zybo/vivado/create_project.jou

bitstream: firmware
	cd $(ROOT) && $(VIVADO) -mode batch -source fpga/zybo/tcl/build_bitstream.tcl \
		-log fpga/zybo/vivado/build_bitstream.log \
		-journal fpga/zybo/vivado/build_bitstream.jou
	@test -f $(BIT) && ls -lh $(BIT)

program:
	@test -f $(BIT) || { echo "Missing $(BIT); run make bitstream"; exit 1; }
	cd $(ROOT) && $(VIVADO) -mode batch -source fpga/zybo/tcl/program_device.tcl \
		-log fpga/zybo/vivado/program.log \
		-journal fpga/zybo/vivado/program.jou

clean:
	rm -rf vivado $(BIT_DIR) *.log *.jou
	$(MAKE) -C $(FW_DIR) clean

help:
	@echo "FPGA targets (Zybo Z7-20 / Vivado):"
	@echo "  make firmware   - build sw/fpga_blink → firmware.mem"
	@echo "  make project    - create Vivado project under fpga/zybo/vivado"
	@echo "  make bitstream  - synth + impl + write $(BIT)"
	@echo "  make program    - JTAG program (board powered + USB JTAG)"
	@echo "  make clean"
	@echo "VIVADO=$(VIVADO)"
