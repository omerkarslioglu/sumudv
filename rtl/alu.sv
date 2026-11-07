`timescale 1ns/100ps

module alu
  import core_pkg::*;
(
  input  logic [XLen-1:0] op_a_i,
  input  logic [XLen-1:0] op_b_i,
  input  operation_t      op_i,
  output logic [XLen-1:0] result_o
);

  always_comb begin
    unique case (op_i)
      ADD:     result_o = op_a_i + op_b_i;
      SUB:     result_o = op_a_i - op_b_i;
      SLT:     result_o = ($signed(op_a_i) < $signed(op_b_i)) ? 32'd1 : 32'd0;
      SLTU:    result_o = (op_a_i < op_b_i) ? 32'd1 : 32'd0;
      XOR:     result_o = op_a_i ^ op_b_i;
      OR:      result_o = op_a_i | op_b_i;
      AND:     result_o = op_a_i & op_b_i;
      SL:      result_o = op_a_i << op_b_i[4:0];
      SRL:     result_o = op_a_i >> op_b_i[4:0];
      SRA:     result_o = $signed(op_a_i) >>> op_b_i[4:0];
      default: result_o = '0;
    endcase
  end

endmodule
