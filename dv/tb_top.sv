`timescale 1ns/100ps

module tb_module;

  `include "riscv.svh"

  logic                   clk_i = 1;
  logic                   rst_ni;
  logic     [InsXLen-1:0] instr_i;
  logic     [AddrLen-1:0] instr_addr_o;
  logic     [   XLen-1:0] data_i;
  logic                   wr_data_en_o;
  logic     [   XLen-1:0] data_o;
  logic     [AddrLen-1:0] data_addr_o;
  logic     mem_width_t   data_width_o;

  core #(
    parameter type mem_width_t = mem_width_t
  ) u_core (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .instr_i (instr_i),
    .instr_addr_o (instr_addr_o),
    .data_i (data_i),
    .wr_data_en_o (wr_data_en_o),
    .data_o (data_o),
    .data_addr_o (data_addr_o),
    .data_width_o (data_width_o)
  );

  initial forever #1 clk_i = ~clk_i;

endmodule