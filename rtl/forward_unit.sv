`timescale 1ns/100ps

module forward_unit
  import core_pkg::*;
(
  input  register_t rs1_i,
  input  register_t rs2_i,
  input  logic      rs1_used_i,
  input  logic      rs2_used_i,
  // EX/MEM
  input  logic      ex_mem_wb_i,
  input  register_t ex_mem_rd_i,
  // MEM/WB
  input  logic      mem_wb_wb_i,
  input  register_t mem_wb_rd_i,
  output logic [1:0] forward_a_o, // 00=RF, 10=EX/MEM, 01=MEM/WB
  output logic [1:0] forward_b_o
);

  always_comb begin
    forward_a_o = 2'b00;
    forward_b_o = 2'b00;

    if (rs1_used_i && ex_mem_wb_i && ex_mem_rd_i != zero && ex_mem_rd_i == rs1_i) begin
      forward_a_o = 2'b10;
    end else if (rs1_used_i && mem_wb_wb_i && mem_wb_rd_i != zero && mem_wb_rd_i == rs1_i) begin
      forward_a_o = 2'b01;
    end

    if (rs2_used_i && ex_mem_wb_i && ex_mem_rd_i != zero && ex_mem_rd_i == rs2_i) begin
      forward_b_o = 2'b10;
    end else if (rs2_used_i && mem_wb_wb_i && mem_wb_rd_i != zero && mem_wb_rd_i == rs2_i) begin
      forward_b_o = 2'b01;
    end
  end

endmodule
