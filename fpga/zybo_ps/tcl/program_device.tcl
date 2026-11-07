# Program Zybo with PS+DDR bitstream (PL = xc7z020, not ARM DAP)
set script_dir [file normalize [file dirname [info script]]]
set zybo_ps    [file normalize [file join $script_dir ..]]
set bitfile    [file join $zybo_ps bitstream sumudv_zybo_ps.bit]

if {![file exists $bitfile]} {
  error "Missing $bitfile — run build_bitstream.tcl first"
}

open_hw_manager
connect_hw_server
open_hw_target

# Zynq JTAG chain lists arm_dap_* first (not programmable). Pick the FPGA.
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
