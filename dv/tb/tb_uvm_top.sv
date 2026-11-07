`timescale 1ns/100ps

module tb_uvm_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sumudv_uvm_pkg::*;

  logic clk_i = 1'b0;
  logic rst_ni;
  logic error_o;

  always #1 clk_i = ~clk_i;

  imem_if imem (.clk_i(clk_i), .rst_ni(rst_ni));
  dmem_if dmem (.clk_i(clk_i), .rst_ni(rst_ni));

  core u_core (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .instr_req_o    (imem.instr_req_o),
    .instr_addr_o   (imem.instr_addr_o),
    .instr_gnt_i    (imem.instr_gnt_i),
    .instr_rvalid_i (imem.instr_rvalid_i),
    .instr_rdata_i  (imem.instr_rdata_i),
    .data_req_o     (dmem.data_req_o),
    .data_we_o      (dmem.data_we_o),
    .data_be_o      (dmem.data_be_o),
    .data_addr_o    (dmem.data_addr_o),
    .data_wdata_o   (dmem.data_wdata_o),
    .data_gnt_i     (dmem.data_gnt_i),
    .data_rvalid_i  (dmem.data_rvalid_i),
    .data_rdata_i   (dmem.data_rdata_i),
    .irq_timer_i    (1'b0),
    .irq_ext_i      (1'b0),
    .error_o        (error_o)
  );

  initial begin
    rst_ni = 1'b0;
    repeat (5) @(posedge clk_i);
    rst_ni = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual imem_if.drv_mp)::set(null, "uvm_test_top.env.imem_agt.driver",  "vif", imem.drv_mp);
    uvm_config_db#(virtual imem_if.mon_mp)::set(null, "uvm_test_top.env.imem_agt.monitor", "vif", imem.mon_mp);
    uvm_config_db#(virtual dmem_if.drv_mp)::set(null, "uvm_test_top.env.dmem_agt.driver",  "vif", dmem.drv_mp);
    uvm_config_db#(virtual dmem_if.mon_mp)::set(null, "uvm_test_top.env.dmem_agt.monitor", "vif", dmem.mon_mp);
    run_test();
  end

endmodule
