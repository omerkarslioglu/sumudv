`timescale 1ns/100ps

// I/D arbiter into one memory port. Data preferred when both request in IDLE.
// Owner held until completing beat (m_gnt && m_rvalid same cycle).
module mem_arbiter (
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
  output logic [31:0] d_rdata_o,

  output logic        m_req_o,
  output logic        m_we_o,
  output logic [3:0]  m_be_o,
  output logic [31:0] m_addr_o,
  output logic [31:0] m_wdata_o,
  input  logic        m_gnt_i,
  input  logic        m_rvalid_i,
  input  logic [31:0] m_rdata_i
);

  typedef enum logic [1:0] { A_IDLE, A_I, A_D } owner_e;
  owner_e owner_q;

  logic done;
  assign done = m_gnt_i && m_rvalid_i;

  always_ff @(posedge clk_i) begin
    if (!rst_ni)
      owner_q <= A_IDLE;
    else begin
      unique case (owner_q)
        A_IDLE: begin
          if (d_req_i)
            owner_q <= A_D;
          else if (i_req_i)
            owner_q <= A_I;
        end
        A_I, A_D: begin
          if (done)
            owner_q <= A_IDLE;
        end
        default: owner_q <= A_IDLE;
      endcase
    end
  end

  always_comb begin
    m_req_o    = 1'b0;
    m_we_o     = 1'b0;
    m_be_o     = 4'hF;
    m_addr_o   = '0;
    m_wdata_o  = '0;
    i_gnt_o    = 1'b0;
    i_rvalid_o = 1'b0;
    i_rdata_o  = m_rdata_i;
    d_gnt_o    = 1'b0;
    d_rvalid_o = 1'b0;
    d_rdata_o  = m_rdata_i;

    // Speculatively drive request from preferred port while idle, or stick with owner.
    if (owner_q == A_D || (owner_q == A_IDLE && d_req_i)) begin
      m_req_o   = d_req_i;
      m_we_o    = d_we_i;
      m_be_o    = d_be_i;
      m_addr_o  = d_addr_i;
      m_wdata_o = d_wdata_i;
      d_gnt_o   = m_gnt_i;
      d_rvalid_o= m_rvalid_i;
      d_rdata_o = m_rdata_i;
    end else if (owner_q == A_I || (owner_q == A_IDLE && i_req_i)) begin
      m_req_o    = i_req_i;
      m_we_o     = 1'b0;
      m_be_o     = 4'hF;
      m_addr_o   = i_addr_i;
      i_gnt_o    = m_gnt_i;
      i_rvalid_o = m_rvalid_i;
      i_rdata_o  = m_rdata_i;
    end
  end

endmodule
