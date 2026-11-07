`timescale 1ns/100ps

interface dmem_if (
  input logic clk_i,
  input logic rst_ni
);

  logic        data_req_o;
  logic        data_we_o;
  logic [3:0]  data_be_o;
  logic [31:0] data_addr_o;
  logic [31:0] data_wdata_o;
  logic        data_gnt_i;
  logic        data_rvalid_i;
  logic [31:0] data_rdata_i;

  clocking mon_cb @(posedge clk_i);
    input data_req_o, data_we_o, data_be_o, data_addr_o, data_wdata_o;
    input data_gnt_i, data_rvalid_i, data_rdata_i;
  endclocking

  clocking drv_cb @(posedge clk_i);
    input  data_req_o, data_we_o, data_be_o, data_addr_o, data_wdata_o;
    output data_gnt_i, data_rvalid_i, data_rdata_i;
  endclocking

  modport mon_mp (clocking mon_cb, input clk_i, rst_ni);
  modport drv_mp (clocking drv_cb, input clk_i, rst_ni);
  modport dut_mp (
    input  clk_i, rst_ni,
    output data_req_o, data_we_o, data_be_o, data_addr_o, data_wdata_o,
    input  data_gnt_i, data_rvalid_i, data_rdata_i
  );

endinterface
