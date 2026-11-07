`timescale 1ns/100ps

interface imem_if (
  input logic clk_i,
  input logic rst_ni
);

  logic        instr_req_o;
  logic [31:0] instr_addr_o;
  logic        instr_gnt_i;
  logic        instr_rvalid_i;
  logic [31:0] instr_rdata_i;

  clocking mon_cb @(posedge clk_i);
    input  instr_req_o, instr_addr_o;
    input  instr_gnt_i, instr_rvalid_i, instr_rdata_i;
  endclocking

  clocking drv_cb @(posedge clk_i);
    input  instr_req_o, instr_addr_o;
    output instr_gnt_i, instr_rvalid_i, instr_rdata_i;
  endclocking

  modport mon_mp (clocking mon_cb, input clk_i, rst_ni);
  modport drv_mp (clocking drv_cb, input clk_i, rst_ni);
  modport dut_mp (
    input  clk_i, rst_ni,
    output instr_req_o, instr_addr_o,
    input  instr_gnt_i, instr_rvalid_i, instr_rdata_i
  );

endinterface
