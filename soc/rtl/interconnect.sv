`timescale 1ns/100ps

// Simple stub interconnect: decode addr → select; 0-latency pass-through.
module interconnect
  import soc_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,

  // Master (core data port)
  input  logic        m_req_i,
  input  logic        m_we_i,
  input  logic [3:0]  m_be_i,
  input  logic [31:0] m_addr_i,
  input  logic [31:0] m_wdata_i,
  output logic        m_gnt_o,
  output logic        m_rvalid_o,
  output logic [31:0] m_rdata_o,

  // Slaves: mem / uart / timer / framebuffer
  output logic        s_mem_req_o,
  output logic        s_uart_req_o,
  output logic        s_timer_req_o,
  output logic        s_fb_req_o,

  output logic        s_we_o,
  output logic [3:0]  s_be_o,
  output logic [31:0] s_addr_o,
  output logic [31:0] s_wdata_o,

  input  logic        s_mem_gnt_i,
  input  logic        s_uart_gnt_i,
  input  logic        s_timer_gnt_i,
  input  logic        s_fb_gnt_i,

  input  logic        s_mem_rvalid_i,
  input  logic        s_uart_rvalid_i,
  input  logic        s_timer_rvalid_i,
  input  logic        s_fb_rvalid_i,

  input  logic [31:0] s_mem_rdata_i,
  input  logic [31:0] s_uart_rdata_i,
  input  logic [31:0] s_timer_rdata_i,
  input  logic [31:0] s_fb_rdata_i
);

  typedef enum logic [1:0] { SEL_MEM, SEL_UART, SEL_TIMER, SEL_FB } sel_e;
  sel_e sel;

  always_comb begin
    if (is_framebuffer(m_addr_i))
      sel = SEL_FB;
    else if (m_addr_i >= TIMER_BASE && m_addr_i < GPIO_BASE)
      sel = SEL_TIMER;
    else if (m_addr_i >= UART_BASE && m_addr_i < TIMER_BASE)
      sel = SEL_UART;
    else
      sel = SEL_MEM;
  end

  assign s_we_o    = m_we_i;
  assign s_be_o    = m_be_i;
  assign s_addr_o  = m_addr_i;
  assign s_wdata_o = m_wdata_i;

  assign s_mem_req_o   = m_req_i && (sel == SEL_MEM);
  assign s_uart_req_o  = m_req_i && (sel == SEL_UART);
  assign s_timer_req_o = m_req_i && (sel == SEL_TIMER);
  assign s_fb_req_o    = m_req_i && (sel == SEL_FB);

  always_comb begin
    unique case (sel)
      SEL_MEM: begin
        m_gnt_o    = s_mem_gnt_i;
        m_rvalid_o = s_mem_rvalid_i;
        m_rdata_o  = s_mem_rdata_i;
      end
      SEL_UART: begin
        m_gnt_o    = s_uart_gnt_i;
        m_rvalid_o = s_uart_rvalid_i;
        m_rdata_o  = s_uart_rdata_i;
      end
      SEL_TIMER: begin
        m_gnt_o    = s_timer_gnt_i;
        m_rvalid_o = s_timer_rvalid_i;
        m_rdata_o  = s_timer_rdata_i;
      end
      default: begin
        m_gnt_o    = s_fb_gnt_i;
        m_rvalid_o = s_fb_rvalid_i;
        m_rdata_o  = s_fb_rdata_i;
      end
    endcase
  end

endmodule
