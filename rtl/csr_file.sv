`timescale 1ns/100ps

module csr_file
  import core_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        csr_access_i,
  input  operation_t  csr_op_i,
  input  logic [11:0] csr_addr_i,
  input  logic [31:0] csr_wdata_i,
  output logic [31:0] csr_rdata_o,
  output logic        csr_illegal_o,
  // trap interface
  input  logic        trap_i,
  input  logic [31:0] trap_cause_i,
  input  logic [31:0] trap_pc_i,
  input  logic [31:0] trap_val_i,
  input  logic        mret_i,
  output logic [31:0] mtvec_o,
  output logic [31:0] mepc_o,
  // retire / cycle
  input  logic        retire_i,
  // external irq
  input  logic        irq_timer_i,
  input  logic        irq_ext_i,
  output logic        irq_pending_o
);

  logic [31:0] mstatus_q, mtvec_q, mepc_q, mcause_q, mtval_q, mie_q, mip_q, mscratch_q;
  logic [63:0] mcycle_q, minstret_q;

  assign mtvec_o = mtvec_q;
  assign mepc_o  = mepc_q;
  assign irq_pending_o = |(mie_q & mip_q) && mstatus_q[3]; // MIE bit

  logic [31:0] rdata;
  logic        illegal;

  always_comb begin
    rdata   = '0;
    illegal = 1'b0;
    unique case (csr_t'(csr_addr_i))
      MSTATUS:   rdata = mstatus_q;
      MTVEC:     rdata = mtvec_q;
      MEPC:      rdata = mepc_q;
      MCAUSE:    rdata = mcause_q;
      MTVAL:     rdata = mtval_q;
      MIE:       rdata = mie_q;
      MIP:       rdata = mip_q;
      MSCRATCH:  rdata = mscratch_q;
      MCYCLE:    rdata = mcycle_q[31:0];
      MCYCLEH:   rdata = mcycle_q[63:32];
      MINSTRET:  rdata = minstret_q[31:0];
      MINSTRETH: rdata = minstret_q[63:32];
      CYCLE:     rdata = mcycle_q[31:0];
      CYCLEH:    rdata = mcycle_q[63:32];
      INSTRET:   rdata = minstret_q[31:0];
      INSTRETH:  rdata = minstret_q[63:32];
      MISA:      rdata = 32'h4000_1100; // RV32 IM
      MVENDORID: rdata = '0;
      MARCHID:   rdata = '0;
      MIMPID:    rdata = '0;
      MHARTID:   rdata = '0;
      default: begin
        rdata   = '0;
        illegal = csr_access_i;
      end
    endcase
  end

  assign csr_rdata_o   = rdata;
  assign csr_illegal_o = illegal;

  logic [31:0] wdata;
  always_comb begin
    unique case (csr_op_i)
      CSRRW:   wdata = csr_wdata_i;
      CSRRS:   wdata = rdata | csr_wdata_i;
      CSRRC:   wdata = rdata & ~csr_wdata_i;
      default: wdata = csr_wdata_i;
    endcase
  end

  // CSRRS/CSRRC with rs1/zimm==0 are reads: must not write (RISC-V spec).
  // Otherwise every `csrr mcycle` writes back and fights the free-running +1.
  logic csr_we;
  assign csr_we = csr_access_i && !illegal
      && ((csr_op_i == CSRRW) || (csr_op_i inside {CSRRS, CSRRC} && csr_wdata_i != '0));

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mstatus_q  <= '0;
      mtvec_q    <= BootAddr;
      mepc_q     <= '0;
      mcause_q   <= '0;
      mtval_q    <= '0;
      mie_q      <= '0;
      mip_q      <= '0;
      mscratch_q <= '0;
      mcycle_q   <= '0;
      minstret_q <= '0;
    end else begin
      mip_q[7]  <= irq_timer_i; // MTIP
      mip_q[11] <= irq_ext_i;   // MEIP

      // Free-running; explicit CSR write overrides below (last assignment wins).
      mcycle_q <= mcycle_q + 64'd1;
      if (retire_i) minstret_q <= minstret_q + 64'd1;

      if (trap_i) begin
        mepc_q           <= trap_pc_i;
        mcause_q         <= trap_cause_i;
        mtval_q          <= trap_val_i;
        mstatus_q[7]     <= mstatus_q[3]; // MPIE <- MIE
        mstatus_q[3]     <= 1'b0;         // MIE <- 0
        mstatus_q[12:11] <= 2'b11;        // MPP <- M
      end else if (mret_i) begin
        mstatus_q[3] <= mstatus_q[7];
        mstatus_q[7] <= 1'b1;
      end else if (csr_we) begin
        unique case (csr_t'(csr_addr_i))
          MSTATUS:   mstatus_q  <= wdata;
          MTVEC:     mtvec_q    <= wdata;
          MEPC:      mepc_q     <= {wdata[31:2], 2'b00};
          MCAUSE:    mcause_q   <= wdata;
          MTVAL:     mtval_q    <= wdata;
          MIE:       mie_q      <= wdata;
          MSCRATCH:  mscratch_q <= wdata;
          MCYCLE:    mcycle_q   <= {mcycle_q[63:32], wdata};
          MCYCLEH:   mcycle_q   <= {wdata, mcycle_q[31:0]};
          MINSTRET:  minstret_q <= {minstret_q[63:32], wdata};
          MINSTRETH: minstret_q <= {wdata, minstret_q[31:0]};
          default: ;
        endcase
      end
    end
  end

endmodule
