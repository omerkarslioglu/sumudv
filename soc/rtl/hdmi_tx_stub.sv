`timescale 1ns/100ps

// HDMI TX timing stub: generates simple 640x480-ish counters; no real TMDS.
module hdmi_tx_stub
  import soc_pkg::*;
(
  input  logic        clk_pix_i,
  input  logic        rst_ni,

  output logic        hdmi_req_o,
  output logic [31:0] hdmi_addr_o,
  input  logic [31:0] hdmi_rdata_i,

  output logic        hsync_o,
  output logic        vsync_o,
  output logic        de_o,
  output logic [7:0]  r_o,
  output logic [7:0]  g_o,
  output logic [7:0]  b_o
);

  localparam int H_VISIBLE = FB_WIDTH;
  localparam int H_TOTAL   = 800;
  localparam int V_VISIBLE = FB_HEIGHT;
  localparam int V_TOTAL   = 525;

  logic [11:0] h_cnt;
  logic [11:0] v_cnt;
  logic [15:0] pix;

  always_ff @(posedge clk_pix_i or negedge rst_ni) begin
    if (!rst_ni) begin
      h_cnt <= '0;
      v_cnt <= '0;
    end else begin
      if (h_cnt == H_TOTAL - 1) begin
        h_cnt <= '0;
        v_cnt <= (v_cnt == V_TOTAL - 1) ? '0 : v_cnt + 1'b1;
      end else begin
        h_cnt <= h_cnt + 1'b1;
      end
    end
  end

  assign de_o    = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
  assign hsync_o = (h_cnt >= 656) && (h_cnt < 752);
  assign vsync_o = (v_cnt >= 490) && (v_cnt < 492);

  assign hdmi_req_o  = de_o;
  assign hdmi_addr_o = FRAMEBUF_BASE + ((v_cnt * H_VISIBLE + h_cnt) << 1);

  assign pix = hdmi_rdata_i[15:0]; // RGB565 low half when even
  assign r_o = de_o ? {pix[15:11], 3'b0} : 8'h0;
  assign g_o = de_o ? {pix[10:5],  2'b0} : 8'h0;
  assign b_o = de_o ? {pix[4:0],   3'b0} : 8'h0;

endmodule
