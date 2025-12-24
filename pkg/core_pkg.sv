package core_pkg;

  parameter int unsigned XLen = 32;
  parameter int unsigned InsXLen = 32;
  parameter int unsigned AddrLen = 32;
  parameter int unsigned BootAddr = 'h80_000_000;

  `include "riscv.svh"

endpackage
