package core_pkg;

  parameter int unsigned XLen     = 32;
  parameter int unsigned InsXLen  = 32;
  parameter int unsigned AddrLen  = 32;
  parameter int unsigned BootAddr = 32'h8000_0000;

  // Cache defaults (Faz 3b)
  parameter int unsigned ICacheWays     = 2;
  parameter int unsigned ICacheSets     = 64;   // 2-way * 64 * 32B = 4 KiB
  parameter int unsigned DCacheWays     = 2;
  parameter int unsigned DCacheSets     = 64;
  parameter int unsigned CacheLineBytes = 32;

  // Branch predictor
  parameter int unsigned BtbEntries = 256;
  parameter int unsigned BhtEntries = 256;

  `include "riscv.svh"

endpackage
