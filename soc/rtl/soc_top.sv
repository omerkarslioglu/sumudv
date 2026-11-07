`timescale 1ns/100ps

// Conceptual SoC top: core + interconnect + peripheral stubs.
// Core instance uses target handshake ports (wired when rtl/core.sv matches).
module soc_top
  import soc_pkg::*;
(
  input  logic clk_i,
  input  logic clk_pix_i,
  input  logic rst_ni,

  output logic hsync_o,
  output logic vsync_o,
  output logic de_o,
  output logic [7:0] r_o,
  output logic [7:0] g_o,
  output logic [7:0] b_o,

  output logic timer_irq_o
);

  // ---- Core instr / data handshake (target) ----
  logic        instr_req, instr_gnt, instr_rvalid;
  logic [31:0] instr_addr, instr_rdata;
  logic        data_req, data_we, data_gnt, data_rvalid;
  logic [3:0]  data_be;
  logic [31:0] data_addr, data_wdata, data_rdata;
  logic error;

  // ---- Interconnect ----
  logic mem_req, uart_req, timer_req, fb_req;
  logic s_we;
  logic [3:0] s_be;
  logic [31:0] s_addr, s_wdata;
  logic mem_gnt, uart_gnt, timer_gnt, fb_gnt;
  logic mem_rvalid, uart_rvalid, timer_rvalid, fb_rvalid;
  logic [31:0] mem_rdata, uart_rdata, timer_rdata, fb_rdata;

  logic        hdmi_req;
  logic [31:0] hdmi_addr, hdmi_rdata;

  // Boot ROM stub: always grant, return NOP (ADDI x0,x0,0)
  assign instr_gnt    = instr_req;
  assign instr_rvalid = instr_req;
  assign instr_rdata  = 32'h0000_0013;

  logic [31:0] ic_hit, ic_miss, dc_hit, dc_miss;

  core_cached #(
    .IBypass(1'b0),
    .DBypass(1'b0)
  ) u_core (
    .clk_i,
    .rst_ni,
    .instr_req_o    (instr_req),
    .instr_addr_o   (instr_addr),
    .instr_gnt_i    (instr_gnt),
    .instr_rvalid_i (instr_rvalid),
    .instr_rdata_i  (instr_rdata),
    .data_req_o     (data_req),
    .data_we_o      (data_we),
    .data_be_o      (data_be),
    .data_addr_o    (data_addr),
    .data_wdata_o   (data_wdata),
    .data_gnt_i     (data_gnt),
    .data_rvalid_i  (data_rvalid),
    .data_rdata_i   (data_rdata),
    .irq_timer_i    (timer_irq_o),
    .irq_ext_i      (1'b0),
    .error_o        (error),
    .icache_hits_o  (ic_hit),
    .icache_misses_o(ic_miss),
    .dcache_hits_o  (dc_hit),
    .dcache_misses_o(dc_miss)
  );

  interconnect u_xbar (
    .clk_i, .rst_ni,
    .m_req_i(data_req), .m_we_i(data_we), .m_be_i(data_be),
    .m_addr_i(data_addr), .m_wdata_i(data_wdata),
    .m_gnt_o(data_gnt), .m_rvalid_o(data_rvalid), .m_rdata_o(data_rdata),
    .s_mem_req_o(mem_req), .s_uart_req_o(uart_req),
    .s_timer_req_o(timer_req), .s_fb_req_o(fb_req),
    .s_we_o(s_we), .s_be_o(s_be), .s_addr_o(s_addr), .s_wdata_o(s_wdata),
    .s_mem_gnt_i(mem_gnt), .s_uart_gnt_i(uart_gnt),
    .s_timer_gnt_i(timer_gnt), .s_fb_gnt_i(fb_gnt),
    .s_mem_rvalid_i(mem_rvalid), .s_uart_rvalid_i(uart_rvalid),
    .s_timer_rvalid_i(timer_rvalid), .s_fb_rvalid_i(fb_rvalid),
    .s_mem_rdata_i(mem_rdata), .s_uart_rdata_i(uart_rdata),
    .s_timer_rdata_i(timer_rdata), .s_fb_rdata_i(fb_rdata)
  );

  // Mem slave stub (always grant, return 0)
  assign mem_gnt    = mem_req;
  assign mem_rvalid = mem_req;
  assign mem_rdata  = '0;

  uart_stub u_uart (
    .clk_i, .rst_ni,
    .req_i(uart_req), .we_i(s_we), .be_i(s_be),
    .addr_i(s_addr), .wdata_i(s_wdata),
    .gnt_o(uart_gnt), .rvalid_o(uart_rvalid), .rdata_o(uart_rdata)
  );

  timer_stub u_timer (
    .clk_i, .rst_ni,
    .req_i(timer_req), .we_i(s_we), .be_i(s_be),
    .addr_i(s_addr), .wdata_i(s_wdata),
    .gnt_o(timer_gnt), .rvalid_o(timer_rvalid), .rdata_o(timer_rdata),
    .irq_o(timer_irq_o)
  );

  framebuffer u_fb (
    .clk_i, .rst_ni,
    .req_i(fb_req), .we_i(s_we), .be_i(s_be),
    .addr_i(s_addr), .wdata_i(s_wdata),
    .gnt_o(fb_gnt), .rvalid_o(fb_rvalid), .rdata_o(fb_rdata),
    .hdmi_req_i(hdmi_req), .hdmi_addr_i(hdmi_addr), .hdmi_rdata_o(hdmi_rdata)
  );

  hdmi_tx_stub u_hdmi (
    .clk_pix_i, .rst_ni,
    .hdmi_req_o(hdmi_req), .hdmi_addr_o(hdmi_addr), .hdmi_rdata_i(hdmi_rdata),
    .hsync_o, .vsync_o, .de_o, .r_o, .g_o, .b_o
  );

endmodule
