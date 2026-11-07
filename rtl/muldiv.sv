`timescale 1ns/100ps

// 2-cycle registered MUL*; iterative restoring DIV/REM (RISC-V M).
module muldiv
  import core_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        valid_i,
  input  operation_t  op_i,
  input  logic [31:0] op_a_i,
  input  logic [31:0] op_b_i,
  output logic        ready_o,
  output logic        valid_o,
  output logic [31:0] result_o
);

  typedef enum logic [1:0] { ST_IDLE, ST_MUL, ST_DIV } state_e;

  state_e      state_q;
  operation_t  op_q;
  logic [31:0] a_q, b_q;
  logic [5:0]  cnt_q;
  logic [31:0] result_q;
  logic        done_q;

  logic [63:0] rem_q;
  logic [31:0] quot_q;
  logic [31:0] divisor_q;
  logic        quot_neg_q, rem_neg_q;

  logic is_mul, is_divop;
  assign is_mul   = op_i inside {MUL, MULH, MULHSU, MULHU};
  assign is_divop = op_i inside {DIV, DIVU, REM, REMU};

  assign ready_o  = done_q;
  assign valid_o  = done_q;
  assign result_o = result_q;

  function automatic logic [31:0] mul_select(
      operation_t op, logic [31:0] a, logic [31:0] b);
    logic [63:0] pu, ps, psu;
    pu  = a * b;
    ps  = $signed(a) * $signed(b);
    psu = $signed({{32{a[31]}}, a}) * $signed({32'b0, b});
    unique case (op)
      MUL:     return pu[31:0];
      MULH:    return ps[63:32];
      MULHSU:  return psu[63:32];
      default: return pu[63:32]; // MULHU
    endcase
  endfunction

  logic a_neg, b_neg, signed_op, ovf, dz;
  logic [31:0] abs_a, abs_b;

  always_comb begin
    signed_op = op_i inside {DIV, REM};
    a_neg     = signed_op && op_a_i[31];
    b_neg     = signed_op && op_b_i[31];
    abs_a     = a_neg ? (~op_a_i + 32'd1) : op_a_i;
    abs_b     = b_neg ? (~op_b_i + 32'd1) : op_b_i;
    dz        = (op_b_i == '0);
    ovf       = signed_op && (op_a_i == 32'h8000_0000) && (op_b_i == 32'hFFFF_FFFF);
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q    <= ST_IDLE;
      done_q     <= 1'b0;
      result_q   <= '0;
      cnt_q      <= '0;
      rem_q      <= '0;
      quot_q     <= '0;
      divisor_q  <= '0;
      quot_neg_q <= 1'b0;
      rem_neg_q  <= 1'b0;
      op_q       <= ADD;
      a_q        <= '0;
      b_q        <= '0;
    end else begin
      done_q <= 1'b0;
      unique case (state_q)
        ST_IDLE: begin
          // !done_q: completion cycle still has valid_i on the same insn.
          if (valid_i && !done_q && is_mul) begin
            a_q     <= op_a_i;
            b_q     <= op_b_i;
            op_q    <= op_i;
            state_q <= ST_MUL;
          end else if (valid_i && !done_q && is_divop) begin
            op_q <= op_i;
            a_q  <= op_a_i;
            b_q  <= op_b_i;
            if (dz) begin
              result_q <= (op_i inside {DIV, DIVU}) ? 32'hFFFF_FFFF : op_a_i;
              done_q   <= 1'b1;
              state_q  <= ST_IDLE;
            end else if (ovf) begin
              result_q <= (op_i == DIV) ? 32'h8000_0000 : 32'h0;
              done_q   <= 1'b1;
              state_q  <= ST_IDLE;
            end else begin
              rem_q      <= {32'b0, abs_a};
              quot_q     <= '0;
              divisor_q  <= abs_b;
              quot_neg_q <= a_neg ^ b_neg;
              rem_neg_q  <= a_neg;
              cnt_q      <= 6'd32;
              state_q    <= ST_DIV;
            end
          end
        end
        ST_MUL: begin
          result_q <= mul_select(op_q, a_q, b_q);
          done_q   <= 1'b1;
          state_q  <= ST_IDLE;
        end
        ST_DIV: begin
          begin
            logic [63:0] shifted, trial;
            logic        ge;
            shifted = {rem_q[62:0], 1'b0};
            ge      = (shifted[63:32] >= divisor_q);
            trial   = ge ? {shifted[63:32] - divisor_q, shifted[31:0]} : shifted;
            rem_q   <= trial;
            quot_q  <= {quot_q[30:0], ge};
            cnt_q   <= cnt_q - 6'd1;
            if (cnt_q == 6'd1) begin
              logic [31:0] q, r;
              q = {quot_q[30:0], ge};
              r = trial[63:32];
              if (quot_neg_q && (q != '0))
                q = ~q + 32'd1;
              if (rem_neg_q && (r != '0))
                r = ~r + 32'd1;
              result_q <= (op_q inside {DIV, DIVU}) ? q : r;
              done_q   <= 1'b1;
              state_q  <= ST_IDLE;
            end
          end
        end
        default: state_q <= ST_IDLE;
      endcase
    end
  end

endmodule
