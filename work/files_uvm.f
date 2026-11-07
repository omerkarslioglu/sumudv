// SUMUD-V UVM compile file list (Questa/ModelSim)
// Usage: vlog -f files_uvm.f +incdir+$UVM_HOME/src

+incdir+../includes
+incdir+../dv/agent/imem_agent
+incdir+../dv/agent/dmem_agent
+incdir+../dv/seq
+incdir+../dv/cov
+incdir+../dv/env
+incdir+../dv/tests
+incdir+../dv/pkg

// Interfaces (compiled outside package)
../dv/interfaces/imem_if.sv
../dv/interfaces/dmem_if.sv

// Package includes all UVM classes in dependency order
../dv/pkg/sumudv_uvm_pkg.sv

// Testbench top
../dv/tb/tb_uvm_top.sv
