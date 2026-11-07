`timescale 1ns/100ps

module btb
  import core_pkg::*;
#(
  parameter int unsigned Entries = BtbEntries
) (
  input  logic                clk_i,
  input  logic                rst_ni,
  // lookup
  input  logic [AddrLen-1:0]  lookup_pc_i,
  output logic                hit_o,
  output logic [AddrLen-1:0]  target_o,
  // update
  input  logic                update_i,
  input  logic [AddrLen-1:0]  update_pc_i,
  input  logic [AddrLen-1:0]  update_target_i
);

  localparam int unsigned IdxBits = $clog2(Entries);

  logic                 valid_q [Entries];
  logic [AddrLen-1:IdxBits+2] tag_q [Entries];
  logic [AddrLen-1:0]   target_q [Entries];

  logic [IdxBits-1:0] lookup_idx, update_idx;

  assign lookup_idx = lookup_pc_i[IdxBits+1:2];
  assign update_idx = update_pc_i[IdxBits+1:2];

  assign hit_o    = valid_q[lookup_idx] && (tag_q[lookup_idx] == lookup_pc_i[AddrLen-1:IdxBits+2]);
  assign target_o = target_q[lookup_idx];

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < Entries; i++) begin
        valid_q[i]  = 1'b0;
        tag_q[i]    = '0;
        target_q[i] = '0;
      end
    end else if (update_i) begin
      valid_q[update_idx]  <= 1'b1;
      tag_q[update_idx]    <= update_pc_i[AddrLen-1:IdxBits+2];
      target_q[update_idx] <= update_target_i;
    end
  end

endmodule
