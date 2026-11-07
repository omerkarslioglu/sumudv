// Auto-generated from config.json
// Do not edit manually!

function void load_cfg_array(ref t_bit_arr cfg_array);
  cfg_array["core.xlen"] = 32;
  cfg_array["core.boot_addr"] = "0x80000000";
  cfg_array["core.pipeline_stages"] = 5;
  cfg_array["core.m_extension"] = 1;
  cfg_array["core.branch_predictor"] = "btb_2bit";
  cfg_array["mem.imem_latency"] = 0;
  cfg_array["mem.dmem_latency"] = 0;
  cfg_array["mem.imem_size_kib"] = 64;
  cfg_array["mem.dmem_size_kib"] = 64;
  cfg_array["cache.icache_enable"] = 0;
  cfg_array["cache.dcache_enable"] = 0;
  cfg_array["cache.icache_kib"] = 4;
  cfg_array["cache.dcache_kib"] = 4;
  cfg_array["sim.timeout_ns"] = 100000;
  cfg_array["sim.plusargs.UVM_TESTNAME"] = "smoke_test";
endfunction
