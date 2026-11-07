# Compatibility shim — prefer fpga/zybo/tcl/create_project.tcl
# Usage (repo root):
#   vivado -mode batch -source fpga/zybo/create_project.tcl
source [file join [file dirname [info script]] tcl create_project.tcl]
