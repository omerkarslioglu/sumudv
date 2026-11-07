# Program Zybo Z7-20 with the latest bitstream (JTAG).
#   vivado -mode batch -source fpga/zybo/tcl/program_device.tcl
#
# Zynq chain exposes arm_dap_* (not programmable) before xc7z020 — select FPGA.

set script_dir [file normalize [file dirname [info script]]]
set zybo_dir   [file normalize [file join $script_dir ..]]
set bitfile    [file join $zybo_dir bitstream sumudv_zybo.bit]

if {![file exists $bitfile]} {
  error "Missing $bitfile — run build_bitstream.tcl first"
}

open_hw_manager
connect_hw_server
open_hw_target

set fpga_devs [get_hw_devices -filter {NAME =~ "*xc7z020*"}]
if {[llength $fpga_devs] == 0} {
  puts "ERROR: Available devices: [get_hw_devices]"
  error "No xc7z020 found — is the Zybo powered and JTAG connected?"
}
set dev [lindex $fpga_devs 0]
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev
set_property PROGRAM.FILE $bitfile $dev
program_hw_devices $dev
refresh_hw_device -update_hw_probes false $dev

puts "INFO: Programmed $bitfile onto [get_property NAME $dev]"
close_hw_manager
