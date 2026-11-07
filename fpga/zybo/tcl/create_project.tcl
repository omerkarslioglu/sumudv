# Create Vivado project for SUMUD-V Zybo Z7-20 PL bring-up bitstream.
# Run from repo root:
#   vivado -mode batch -source fpga/zybo/tcl/create_project.tcl
# Or from Vivado TCL console after cd to repo root.

set script_dir [file normalize [file dirname [info script]]]
set zybo_dir   [file normalize [file join $script_dir ..]]
set root       [file normalize [file join $zybo_dir ../..]]
set proj_name  sumudv_zybo
set proj_dir   [file join $zybo_dir vivado]

puts "INFO: root=$root"
puts "INFO: Creating project $proj_name in $proj_dir"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

# Board part optional (Digilent board files). Part alone is enough for bitstream.
if {[llength [get_board_parts -quiet digilentinc.com:zybo-z7-20*]] > 0} {
  set_property board_part [lindex [get_board_parts digilentinc.com:zybo-z7-20*] 0] [current_project]
  puts "INFO: board_part set"
} else {
  puts "WARN: Digilent Zybo Z7-20 board files not found — using part only"
}

set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

# ---- Sources (packages first) ----
set pkg_files [list \
  [file join $root pkg core_pkg.sv] \
]

set rtl_files [list \
  [file join $root rtl alu.sv] \
  [file join $root rtl regfile.sv] \
  [file join $root rtl lsu.sv] \
  [file join $root rtl muldiv.sv] \
  [file join $root rtl btb.sv] \
  [file join $root rtl branch_predictor.sv] \
  [file join $root rtl forward_unit.sv] \
  [file join $root rtl hazard_unit.sv] \
  [file join $root rtl csr_file.sv] \
  [file join $root rtl decoder.sv] \
  [file join $root rtl core.sv] \
]

set fpga_files [list \
  [file join $zybo_dir rtl clk_wiz_50.sv] \
  [file join $zybo_dir rtl fpga_bram.sv] \
  [file join $zybo_dir rtl uart_tx.sv] \
  [file join $zybo_dir rtl gpio_leds.sv] \
  [file join $zybo_dir rtl fpga_top.sv] \
]

add_files -norecurse $pkg_files
add_files -norecurse $rtl_files
add_files -norecurse $fpga_files

set_property file_type SystemVerilog [get_files *.sv]
set_property include_dirs [list [file join $root includes]] [current_fileset]
set_property top fpga_top [current_fileset]
update_compile_order -fileset sources_1

# Firmware memory init (copy into project so $readmemh finds it)
set fw_src [file join $root sw fpga_blink build fpga_blink.mem]
set fw_dst [file join $proj_dir firmware.mem]
if {[file exists $fw_src]} {
  file copy -force $fw_src $fw_dst
  puts "INFO: Copied firmware.mem from sw/fpga_blink/build"
} else {
  puts "WARN: $fw_src missing — run: make -C sw/fpga_blink"
  # Empty NOP image so elaboration still succeeds
  set fd [open $fw_dst w]
  for {set i 0} {$i < 16} {incr i} { puts $fd "00000013" }
  close $fd
}

set_property generic [list MemInit=[file normalize $fw_dst]] [get_filesets sources_1]

# Constraints
add_files -fileset constrs_1 -norecurse [file join $zybo_dir constrs zybo_z7_20.xdc]

puts "INFO: Project ready."
puts "INFO: Next: vivado -mode batch -source fpga/zybo/tcl/build_bitstream.tcl"
