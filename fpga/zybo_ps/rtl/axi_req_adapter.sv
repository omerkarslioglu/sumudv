`timescale 1ns/100ps

// Single-outstanding AXI4-Lite master from SUMUD-V req/gnt handshake.
// Core needs gnt && rvalid in the same cycle to retire a memory op — both
// are asserted together only on the completing response beat.
// CPU 0x8000_0000 window → PS DDR via AddrOffset subtract.
module axi_req_adapter #(
  parameter logic [31:0] AddrOffset = 32'h8000_0000
) (
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

  output logic [31:0] m_axi_awaddr,
  output logic [2:0]  m_axi_awprot,
  output logic        m_axi_awvalid,
  input  logic        m_axi_awready,
  output logic [31:0] m_axi_wdata,
  output logic [3:0]  m_axi_wstrb,
  output logic        m_axi_wvalid,
  input  logic        m_axi_wready,
  input  logic [1:0]  m_axi_bresp,
  input  logic        m_axi_bvalid,
  output logic        m_axi_bready,
  output logic [31:0] m_axi_araddr,
  output logic [2:0]  m_axi_arprot,
  output logic        m_axi_arvalid,
  input  logic        m_axi_arready,
  input  logic [31:0] m_axi_rdata,
  input  logic [1:0]  m_axi_rresp,
  input  logic        m_axi_rvalid,
  output logic        m_axi_rready
);

  typedef enum logic [2:0] {
    IDLE,
    W_ADDR_DATA,
    W_RESP,
    R_ADDR,
    R_DATA
  } state_e;

  state_e state_q;
  logic [31:0] addr_q, wdata_q, rdata_q;
  logic [3:0]  be_q;
  logic        aw_done_q, w_done_q;
  logic        we_q;

  logic [31:0] phys_addr;
  assign phys_addr = addr_q - AddrOffset;

  assign m_axi_awprot = 3'b000;
  assign m_axi_arprot = 3'b000;
  assign m_axi_awaddr = phys_addr;
  assign m_axi_araddr = phys_addr;
  assign m_axi_wdata  = wdata_q;
  assign m_axi_wstrb  = be_q;

  always_comb begin
    gnt_o         = 1'b0;
    rvalid_o      = 1'b0;
    rdata_o       = rdata_q;
    m_axi_awvalid = 1'b0;
    m_axi_wvalid  = 1'b0;
    m_axi_bready  = 1'b0;
    m_axi_arvalid = 1'b0;
    m_axi_rready  = 1'b0;

    unique case (state_q)
      W_ADDR_DATA: begin
        m_axi_awvalid = ~aw_done_q;
        m_axi_wvalid  = ~w_done_q;
      end
      W_RESP: begin
        m_axi_bready = 1'b1;
        if (m_axi_bvalid) begin
          gnt_o    = 1'b1;
          rvalid_o = 1'b1;
          rdata_o  = wdata_q;
        end
      end
      R_ADDR: begin
        m_axi_arvalid = 1'b1;
      end
      R_DATA: begin
        m_axi_rready = 1'b1;
        if (m_axi_rvalid) begin
          gnt_o    = 1'b1;
          rvalid_o = 1'b1;
          rdata_o  = m_axi_rdata;
        end
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q   <= IDLE;
      addr_q    <= '0;
      wdata_q   <= '0;
      be_q      <= '0;
      rdata_q   <= '0;
      we_q      <= 1'b0;
      aw_done_q <= 1'b0;
      w_done_q  <= 1'b0;
    end else begin
      unique case (state_q)
        IDLE: begin
          aw_done_q <= 1'b0;
          w_done_q  <= 1'b0;
          if (req_i) begin
            addr_q  <= addr_i;
            wdata_q <= wdata_i;
            be_q    <= be_i;
            we_q    <= we_i;
            state_q <= we_i ? W_ADDR_DATA : R_ADDR;
          end
        end
        W_ADDR_DATA: begin
          if (!aw_done_q && m_axi_awvalid && m_axi_awready)
            aw_done_q <= 1'b1;
          if (!w_done_q && m_axi_wvalid && m_axi_wready)
            w_done_q <= 1'b1;
          if ((aw_done_q || (m_axi_awvalid && m_axi_awready)) &&
              (w_done_q  || (m_axi_wvalid  && m_axi_wready)))
            state_q <= W_RESP;
        end
        W_RESP: begin
          if (m_axi_bvalid && m_axi_bready) begin
            rdata_q <= wdata_q;
            state_q <= IDLE;
          end
        end
        R_ADDR: begin
          if (m_axi_arvalid && m_axi_arready)
            state_q <= R_DATA;
        end
        R_DATA: begin
          if (m_axi_rvalid && m_axi_rready) begin
            rdata_q <= m_axi_rdata;
            state_q <= IDLE;
          end
        end
        default: state_q <= IDLE;
      endcase
    end
  end

  logic _unused;
  assign _unused = |m_axi_bresp | |m_axi_rresp | we_q;

endmodule
