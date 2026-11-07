# Create Vivado project for SUMUD-V Zybo PS+DDR bring-up.
# Run from repo root:
#   vivado -mode batch -source fpga/zybo_ps/tcl/create_project.tcl

set script_dir [file normalize [file dirname [info script]]]
set zybo_ps    [file normalize [file join $script_dir ..]]
set root       [file normalize [file join $zybo_ps ../..]]
set zybo_pl    [file normalize [file join $root fpga zybo]]
set proj_name  sumudv_zybo_ps
set proj_dir   [file join $zybo_ps vivado]

puts "INFO: root=$root"
file mkdir $proj_dir

# Digilent board files (user-local or repo helper path)
set board_repo ""
foreach cand [list \
    [file join $::env(HOME) Xilinx vivado-boards board_files] \
    [file join $::env(HOME) .Xilinx Vivado board_files] \
  ] {
  if {[file isdirectory $cand]} {
    set board_repo $cand
    break
  }
}
if {$board_repo ne ""} {
  set_param board.repoPaths [list $board_repo]
  puts "INFO: board.repoPaths=$board_repo"
}

create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

if {[llength [get_board_parts -quiet digilentinc.com:zybo-z7-20*]] > 0} {
  set_property board_part [lindex [get_board_parts digilentinc.com:zybo-z7-20*] 0] [current_project]
  puts "INFO: board_part set to zybo-z7-20"
} else {
  puts "WARN: Digilent zybo-z7-20 board files not found"
  puts "WARN: Install https://github.com/Digilent/vivado-boards for reliable DDR preset"
}

set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

# Block design
source [file join $zybo_ps bd create_bd.tcl]

# Wrapper
set bd_file [get_files design_1.bd]
set wrapper [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper
set_property top fpga_top_ps [current_fileset]

# RTL
set pkg_files [list [file join $root pkg core_pkg.sv]]
set rtl_core [list \
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
set rtl_fpga [list \
  [file join $zybo_pl rtl uart_tx.sv] \
  [file join $zybo_pl rtl gpio_leds.sv] \
  [file join $zybo_ps rtl axi_req_adapter.sv] \
  [file join $zybo_ps rtl mem_arbiter.sv] \
  [file join $zybo_ps rtl fpga_top_ps.sv] \
]

add_files -norecurse $pkg_files
add_files -norecurse $rtl_core
add_files -norecurse $rtl_fpga
set_property file_type SystemVerilog [get_files *.sv]
set_property include_dirs [list [file join $root includes]] [current_fileset]

add_files -fileset constrs_1 -norecurse [file join $zybo_ps constrs zybo_z7_20_ps.xdc]

update_compile_order -fileset sources_1
puts "INFO: Project $proj_name ready (top=fpga_top_ps)"
