`timescale 1ns/100ps

// Dual-port stub: CPU write port + HDMI read port (simple BRAM model).
module framebuffer
  import soc_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,

  // CPU port
  input  logic        req_i,
  input  logic        we_i,
  input  logic [3:0]  be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic        gnt_o,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,

  // HDMI scanout port (read-only)
  input  logic        hdmi_req_i,
  input  logic [31:0] hdmi_addr_i,
  output logic [31:0] hdmi_rdata_o
);

  localparam int unsigned DEPTH = (FB_WIDTH * FB_HEIGHT) / 2; // 2 px / word @ 16bpp

  logic [31:0] mem [DEPTH];
  logic [31:0] word_idx;
  logic [31:0] hdmi_idx;

  assign word_idx = (addr_i - FRAMEBUF_BASE) >> 2;
  assign hdmi_idx = (hdmi_addr_i - FRAMEBUF_BASE) >> 2;
  assign gnt_o    = req_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid_o    <= 1'b0;
      rdata_o     <= '0;
      hdmi_rdata_o <= '0;
    end else begin
      rvalid_o <= req_i;

      if (req_i && we_i && word_idx < DEPTH) begin
        if (be_i[0]) mem[word_idx][7:0]   <= wdata_i[7:0];
        if (be_i[1]) mem[word_idx][15:8]  <= wdata_i[15:8];
        if (be_i[2]) mem[word_idx][23:16] <= wdata_i[23:16];
        if (be_i[3]) mem[word_idx][31:24] <= wdata_i[31:24];
      end

      if (req_i && !we_i && word_idx < DEPTH)
        rdata_o <= mem[word_idx];
      else
        rdata_o <= '0;

      if (hdmi_req_i && hdmi_idx < DEPTH)
        hdmi_rdata_o <= mem[hdmi_idx];
      else
        hdmi_rdata_o <= '0;
    end
  end

endmodule
