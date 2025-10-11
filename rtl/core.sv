module core 
  import core_pkg::*;
(
  input                   clk_i,
  input                   rst_ni,
  // L1 instruction cache port
  input     [InsXLen-1:0] instr_i,
  output    [AddrLen-1:0] instr_addr_o,
  // L1 data cache port
  input     [   XLen-1:0] data_i,
  output                  wr_data_en_o,
  output    [   XLen-1:0] data_o,
  output    [AddrLen-1:0] data_addr_o
);

  `include "riscv.svh"

  localparam unsigned int WordByteOffset = 4;

  logic [AddrLen-1:0] pc;

  always_comb begin
    instr_addr_o = pc;
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc <= BootAddr;
    end else begin
      pc <= pc + WordByteOffset;
    end
  end

endmodule
