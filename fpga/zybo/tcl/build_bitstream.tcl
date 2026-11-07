# Synthesize / implement / write bitstream for SUMUD-V Zybo project.
# Prefer:
#   make -C fpga/zybo bitstream
# Or (repo root, project already created):
#   vivado -mode batch -source fpga/zybo/tcl/build_bitstream.tcl

set script_dir [file normalize [file dirname [info script]]]
set zybo_dir   [file normalize [file join $script_dir ..]]
set proj_dir   [file join $zybo_dir vivado]
set proj_xpr   [file join $proj_dir sumudv_zybo.xpr]
set jobs       8

if {![file exists $proj_xpr]} {
  puts "INFO: Project missing — creating..."
  source [file join $script_dir create_project.tcl]
} else {
  open_project $proj_xpr
}

# Refresh firmware.mem if rebuilt
set root   [file normalize [file join $zybo_dir ../..]]
set fw_src [file join $root sw fpga_blink build fpga_blink.mem]
set fw_dst [file join $proj_dir firmware.mem]
if {[file exists $fw_src]} {
  file copy -force $fw_src $fw_dst
  set_property generic [list MemInit=[file normalize $fw_dst]] [get_filesets sources_1]
}

reset_run synth_1
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
  error "Synthesis failed"
}

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  error "Implementation / bitstream failed"
}

set bitfile [file join $proj_dir sumudv_zybo.runs impl_1 fpga_top.bit]
set out_bit [file join $zybo_dir bitstream sumudv_zybo.bit]
file mkdir [file join $zybo_dir bitstream]
file copy -force $bitfile $out_bit

puts "========================================"
puts "BITSTREAM OK: $out_bit"
puts "Program: make -C fpga/zybo program"
puts "========================================"
