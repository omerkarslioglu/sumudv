# Synth / impl / bitstream for sumudv_zybo_ps
set script_dir [file normalize [file dirname [info script]]]
set zybo_ps    [file normalize [file join $script_dir ..]]
set proj_dir   [file join $zybo_ps vivado]
set proj_xpr   [file join $proj_dir sumudv_zybo_ps.xpr]
set jobs       8

if {![file exists $proj_xpr]} {
  puts "INFO: Project missing — creating..."
  source [file join $script_dir create_project.tcl]
} else {
  open_project $proj_xpr
}

reset_run synth_1
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
  error "SYNTH_FAILED"
}

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  error "IMPL_FAILED"
}

set bitfile [file join $proj_dir sumudv_zybo_ps.runs impl_1 fpga_top_ps.bit]
set hwh     [file join $proj_dir sumudv_zybo_ps.gen sources_1 bd design_1 hw_handoff design_1.hwh]
if {![file exists $hwh]} {
  set hwh [file join $proj_dir sumudv_zybo_ps.srcs sources_1 bd design_1 hw_handoff design_1.hwh]
}
set ps7_init [file join $proj_dir sumudv_zybo_ps.gen sources_1 bd design_1 \
  ip design_1_processing_system7_0_0 ps7_init.tcl]
set out_dir [file join $zybo_ps bitstream]
file mkdir $out_dir
file copy -force $bitfile [file join $out_dir sumudv_zybo_ps.bit]
if {[file exists $hwh]} {
  file copy -force $hwh [file join $out_dir design_1.hwh]
}
if {[file exists $ps7_init]} {
  file copy -force $ps7_init [file join $out_dir ps7_init.tcl]
}

# Export GPIO base address hint for load script
set addr_file [file join $out_dir gpio_cpu_run_addr.txt]
set fd [open $addr_file w]
puts $fd "0x41200000"
close $fd

puts "========================================"
puts "BITSTREAM OK: $out_dir/sumudv_zybo_ps.bit"
puts "========================================"
