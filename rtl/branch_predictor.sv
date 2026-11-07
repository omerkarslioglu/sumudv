`timescale 1ns/100ps

// BTB + 2-bit BHT + 8-entry RAS (updated at EX resolve).
module branch_predictor
  import core_pkg::*;
(
  input  logic               clk_i,
  input  logic               rst_ni,
  input  logic [AddrLen-1:0] pc_i,
  input  logic [InsXLen-1:0] instr_i,
  input  logic               instr_valid_i,
  output logic               predict_taken_o,
  output logic [AddrLen-1:0] predict_target_o,
  input  logic               resolve_i,
  input  logic               resolve_is_branch_i,
  input  logic               resolve_is_jump_i,
  input  logic               resolve_taken_i,
  input  logic [AddrLen-1:0] resolve_pc_i,
  input  logic [AddrLen-1:0] resolve_target_i,
  input  register_t          resolve_rd_i,
  input  register_t          resolve_rs1_i,
  output logic [31:0]        bp_lookups_o,
  output logic [31:0]        bp_correct_o
);

  localparam int unsigned IdxBits   = $clog2(BhtEntries);
  localparam int unsigned RasEntries = 8;
  localparam int unsigned RasPtrW    = $clog2(RasEntries);

  logic [1:0] bht_q [BhtEntries];
  logic [IdxBits-1:0] lookup_idx, resolve_idx;
  logic btb_hit;
  logic [AddrLen-1:0] btb_target;

  assign lookup_idx  = pc_i[IdxBits+1:2];
  assign resolve_idx = resolve_pc_i[IdxBits+1:2];

  btb u_btb (
    .clk_i,
    .rst_ni,
    .lookup_pc_i     (pc_i),
    .hit_o           (btb_hit),
    .target_o        (btb_target),
    .update_i        (resolve_i && (resolve_taken_i || resolve_is_jump_i)),
    .update_pc_i     (resolve_pc_i),
    .update_target_i (resolve_target_i)
  );

  // RAS
  logic [AddrLen-1:0] ras_q [RasEntries];
  logic [RasPtrW:0]   ras_count_q;
  logic [AddrLen-1:0] ras_top;
  logic               ras_ret;

  logic is_jalr_if;
  assign is_jalr_if = instr_valid_i && (instr_i[6:0] == 7'b1100111)
                   && (instr_i[14:12] == 3'b000);
  assign ras_ret = is_jalr_if && (instr_i[11:7] == 5'd0)
                && (instr_i[19:15] == 5'd1) && (ras_count_q != '0);
  assign ras_top = (ras_count_q == '0) ? '0
                 : ras_q[ras_count_q[RasPtrW-1:0] - RasPtrW'(1)];

  // BTB hit means this PC previously taken/jumped (tagged).
  assign predict_taken_o  = ras_ret || btb_hit;
  assign predict_target_o = ras_ret ? ras_top : btb_target;

  logic [31:0] lookups_q, correct_q;
  assign bp_lookups_o = lookups_q;
  assign bp_correct_o = correct_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < BhtEntries; i++)
        bht_q[i] = 2'b01;
      for (int i = 0; i < RasEntries; i++)
        ras_q[i] = '0;
      ras_count_q <= '0;
      lookups_q   <= '0;
      correct_q   <= '0;
    end else begin
      if (resolve_i && resolve_is_branch_i) begin
        lookups_q <= lookups_q + 32'd1;
        if (resolve_taken_i == bht_q[resolve_idx][1])
          correct_q <= correct_q + 32'd1;
        if (resolve_taken_i) begin
          if (bht_q[resolve_idx] != 2'b11)
            bht_q[resolve_idx] <= bht_q[resolve_idx] + 2'd1;
        end else if (bht_q[resolve_idx] != 2'b00) begin
          bht_q[resolve_idx] <= bht_q[resolve_idx] - 2'd1;
        end
      end

      if (resolve_i && resolve_is_jump_i) begin
        logic [RasPtrW:0] ras_sp;
        ras_sp = ras_count_q;
        if ((resolve_rs1_i == ra) && (ras_sp != '0))
          ras_sp = ras_sp - 1'b1;
        if (resolve_rd_i == ra) begin
          if (ras_sp < RasEntries[RasPtrW:0]) begin
            ras_q[ras_sp[RasPtrW-1:0]] <= resolve_pc_i + 32'd4;
            ras_sp = ras_sp + 1'b1;
          end
        end
        ras_count_q <= ras_sp;
      end
    end
  end

endmodule
