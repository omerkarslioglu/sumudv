`timescale 1ns/100ps

// Free-running 64-bit mtime-style timer stub + compare interrupt.
module timer_stub (
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        req_i,
  input  logic        we_i,
  input  logic [3:0]  be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic        gnt_o,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,

  output logic        irq_o
);

  localparam logic [7:0] OFF_MTIME_LO  = 8'h00;
  localparam logic [7:0] OFF_MTIME_HI  = 8'h04;
  localparam logic [7:0] OFF_MTIMECMP_LO = 8'h08;
  localparam logic [7:0] OFF_MTIMECMP_HI = 8'h0C;

  logic [63:0] mtime;
  logic [63:0] mtimecmp;

  assign gnt_o = req_i;
  assign irq_o = (mtime >= mtimecmp);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mtime     <= '0;
      mtimecmp  <= {64{1'b1}};
      rvalid_o  <= 1'b0;
      rdata_o   <= '0;
    end else begin
      mtime    <= mtime + 64'd1;
      rvalid_o <= req_i;

      if (req_i && we_i) begin
        unique case (addr_i[7:0])
          OFF_MTIME_LO:    if (be_i == 4'hF) mtime[31:0]     <= wdata_i;
          OFF_MTIME_HI:    if (be_i == 4'hF) mtime[63:32]    <= wdata_i;
          OFF_MTIMECMP_LO: if (be_i == 4'hF) mtimecmp[31:0]  <= wdata_i;
          OFF_MTIMECMP_HI: if (be_i == 4'hF) mtimecmp[63:32] <= wdata_i;
          default: ;
        endcase
      end

      if (req_i && !we_i) begin
        unique case (addr_i[7:0])
          OFF_MTIME_LO:    rdata_o <= mtime[31:0];
          OFF_MTIME_HI:    rdata_o <= mtime[63:32];
          OFF_MTIMECMP_LO: rdata_o <= mtimecmp[31:0];
          OFF_MTIMECMP_HI: rdata_o <= mtimecmp[63:32];
          default:         rdata_o <= '0;
        endcase
      end else begin
        rdata_o <= '0;
      end
    end
  end

endmodule
