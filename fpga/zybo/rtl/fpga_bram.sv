`timescale 1ns/100ps

// True dual-port Block RAM (UG901): byte-write on port B, read-only port A.
// No reset on the memory array (required for BRAM + $readmemh init).
// Latency: req on cycle N → gnt+rvalid+data on N+1.
module fpga_bram #(
  parameter int unsigned DepthWords = 16384, // 64 KiB
  parameter string       InitFile   = ""
) (
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        i_req_i,
  input  logic [31:0] i_addr_i,
  output logic        i_gnt_o,
  output logic        i_rvalid_o,
  output logic [31:0] i_rdata_o,

  input  logic        d_req_i,
  input  logic        d_we_i,
  input  logic [3:0]  d_be_i,
  input  logic [31:0] d_addr_i,
  input  logic [31:0] d_wdata_i,
  output logic        d_gnt_o,
  output logic        d_rvalid_o,
  output logic [31:0] d_rdata_o
);

  localparam int unsigned Aw = $clog2(DepthWords);

  (* ram_style = "block" *) logic [31:0] mem [DepthWords];

  // Direct $readmemh into the RAM array (Vivado BRAM init)
  initial begin
    if (InitFile != "")
      $readmemh(InitFile, mem);
    else begin
      for (int i = 0; i < DepthWords; i++)
        mem[i] = 32'h0000_0013;
    end
  end

  logic [Aw-1:0] i_idx, d_idx;
  assign i_idx = i_addr_i[Aw+1:2];
  assign d_idx = d_addr_i[Aw+1:2];

  logic [31:0] i_q, d_q;

  // Port A — registered read
  always_ff @(posedge clk_i) begin
    i_q <= mem[i_idx];
  end

  // Port B — byte WE + registered read (UG901)
  always_ff @(posedge clk_i) begin
    if (d_req_i && d_we_i && d_be_i[0]) mem[d_idx][7:0]   <= d_wdata_i[7:0];
    if (d_req_i && d_we_i && d_be_i[1]) mem[d_idx][15:8]  <= d_wdata_i[15:8];
    if (d_req_i && d_we_i && d_be_i[2]) mem[d_idx][23:16] <= d_wdata_i[23:16];
    if (d_req_i && d_we_i && d_be_i[3]) mem[d_idx][31:24] <= d_wdata_i[31:24];
    d_q <= mem[d_idx];
  end

  logic        i_req_q, d_req_q, d_we_q;
  logic [31:0] d_wdata_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      i_req_q    <= 1'b0;
      d_req_q    <= 1'b0;
      d_we_q     <= 1'b0;
      d_wdata_q  <= '0;
      i_gnt_o    <= 1'b0;
      i_rvalid_o <= 1'b0;
      i_rdata_o  <= '0;
      d_gnt_o    <= 1'b0;
      d_rvalid_o <= 1'b0;
      d_rdata_o  <= '0;
    end else begin
      i_req_q    <= i_req_i;
      i_gnt_o    <= i_req_q;
      i_rvalid_o <= i_req_q;
      i_rdata_o  <= i_req_q ? i_q : '0;

      d_req_q    <= d_req_i;
      d_we_q     <= d_we_i;
      d_wdata_q  <= d_wdata_i;
      d_gnt_o    <= d_req_q;
      d_rvalid_o <= d_req_q;
      if (d_req_q)
        d_rdata_o <= d_we_q ? d_wdata_q : d_q;
      else
        d_rdata_o <= '0;
    end
  end

endmodule
