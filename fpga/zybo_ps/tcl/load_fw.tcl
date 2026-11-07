# Load RISC-V firmware into PS DDR and release cpu_run via AXI GPIO.
# Requires: bitstream already programmed; xsdb (Vivado 2025.1+) or xsct.
# Usage (repo root):
#   xsdb fpga/zybo_ps/tcl/load_fw.tcl

set script_dir [file normalize [file dirname [info script]]]
set zybo_ps    [file normalize [file join $script_dir ..]]
set root       [file normalize [file join $zybo_ps ../..]]
set binfile    [file join $root sw fpga_ddr_memtest build fpga_ddr_memtest.bin]
set addrfile   [file join $zybo_ps bitstream gpio_cpu_run_addr.txt]
set ps7_init   [file join $zybo_ps bitstream ps7_init.tcl]
if {![file exists $ps7_init]} {
  set ps7_init [file join $zybo_ps vivado sumudv_zybo_ps.gen sources_1 bd design_1 \
    ip design_1_processing_system7_0_0 ps7_init.tcl]
}

if {![file exists $binfile]} {
  error "Missing $binfile — run: make -C sw/fpga_ddr_memtest"
}

set gpio_addr 0x41200000
if {[file exists $addrfile]} {
  set fd [open $addrfile r]
  set gpio_addr [string trim [read $fd]]
  close $fd
}

puts "INFO: Connecting hw_server..."
connect
targets
# Prefer A9 core 0 (names vary across Vivado/Vitis releases)
if {[catch {targets -set -filter {name =~ "ARM*#0"}}]} {
  if {[catch {targets -set -filter {name =~ "*Cortex-A9 MPCore #0"}}]} {
    targets -set -filter {name =~ "*A9*#0"}
  }
}
catch {stop}
after 200

# DDR / FCLK require PS init after cold power or PL-only program
if {[file exists $ps7_init]} {
  puts "INFO: Sourcing $ps7_init"
  source $ps7_init
  ps7_init
  ps7_post_config
} else {
  puts "WARNING: ps7_init.tcl not found — DDR may be unusable until PS is initialized"
}

# Debugger blocks PL AXI unless forced (no HSI memmap for GP0 slaves)
catch {configparams force-mem-accesses 1}

after 200

# Hold RISC-V reset (cpu_run=0)
puts "INFO: cpu_run=0 (GPIO $gpio_addr)"
mwr -force $gpio_addr 0

# Physical DDR base 0x0 == CPU 0x80000000 after adapter offset
puts "INFO: Loading $binfile @ 0x00000000"
dow -data $binfile 0x00000000

# Release RISC-V
puts "INFO: cpu_run=1"
mwr -force $gpio_addr 1

puts "INFO: Firmware running — watch UART 115200 for 'DDR PASS'"
disconnect
exit
