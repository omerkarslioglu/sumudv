`timescale 1ns/100ps

module regfile
  import core_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  register_t   raddr_a_i,
  input  register_t   raddr_b_i,
  output logic [31:0] rdata_a_o,
  output logic [31:0] rdata_b_o,
  input  logic        we_i,
  input  register_t   waddr_i,
  input  logic [31:0] wdata_i
);

  logic [31:0] registers [32];

  // Write-through read: same-cycle WB must be visible to ID→EX latch (avoids
  // NBA race where a store base/address captures x0 before lui/addi commits).
  assign rdata_a_o = (raddr_a_i == zero) ? '0
                   : (we_i && waddr_i == raddr_a_i) ? wdata_i
                   : registers[raddr_a_i];
  assign rdata_b_o = (raddr_b_i == zero) ? '0
                   : (we_i && waddr_i == raddr_b_i) ? wdata_i
                   : registers[raddr_b_i];

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < 32; i++) begin
        registers[i] <= '0;
      end
    end else if (we_i && waddr_i != zero) begin
      registers[waddr_i] <= wdata_i;
    end
  end

endmodule
