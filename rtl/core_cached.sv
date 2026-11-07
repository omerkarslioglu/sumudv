`timescale 1ns/100ps

// Core + optional L1 I$/D$. Set IBypass/DBypass=0 for real cache.
module core_cached
  import core_pkg::*;
#(
  parameter bit IBypass = 1'b0,
  parameter bit DBypass = 1'b0
) (
  input  logic               clk_i,
  input  logic               rst_ni,

  // Outer memory (DDR / interconnect)
  output logic               instr_req_o,
  output logic [AddrLen-1:0] instr_addr_o,
  input  logic               instr_gnt_i,
  input  logic               instr_rvalid_i,
  input  logic [InsXLen-1:0] instr_rdata_i,

  output logic               data_req_o,
  output logic               data_we_o,
  output logic [3:0]         data_be_o,
  output logic [AddrLen-1:0] data_addr_o,
  output logic [XLen-1:0]    data_wdata_o,
  input  logic               data_gnt_i,
  input  logic               data_rvalid_i,
  input  logic [XLen-1:0]    data_rdata_i,

  input  logic               irq_timer_i,
  input  logic               irq_ext_i,
  output logic               error_o,

  output logic [31:0]        icache_hits_o,
  output logic [31:0]        icache_misses_o,
  output logic [31:0]        dcache_hits_o,
  output logic [31:0]        dcache_misses_o
);

  // CPU <-> cache
  logic        c_ireq, c_ignt, c_irvalid;
  logic [31:0] c_iaddr, c_irdata;
  logic        c_dreq, c_dwe, c_dgnt, c_drvalid;
  logic [3:0]  c_dbe;
  logic [31:0] c_daddr, c_dwdata, c_drdata;

  logic        s_req, s_we, s_gnt, s_rvalid;
  logic [3:0]  s_be;
  logic [31:0] s_addr, s_wdata, s_rdata;

  store_buffer u_sb (
    .clk_i,
    .rst_ni,
    .req_i       (c_dreq),
    .we_i        (c_dwe),
    .be_i        (c_dbe),
    .addr_i      (c_daddr),
    .wdata_i     (c_dwdata),
    .gnt_o       (c_dgnt),
    .rvalid_o    (c_drvalid),
    .rdata_o     (c_drdata),
    .mem_req_o   (s_req),
    .mem_we_o    (s_we),
    .mem_be_o    (s_be),
    .mem_addr_o  (s_addr),
    .mem_wdata_o (s_wdata),
    .mem_gnt_i   (s_gnt),
    .mem_rvalid_i(s_rvalid),
    .mem_rdata_i (s_rdata)
  );

  // Uncached MMIO / framebuffer window: bypass D$
  logic d_uncached;
  assign d_uncached = (s_addr[31:28] == 4'h1) || // MMIO 0x1xxx_xxxx
                      (s_addr[31:28] == 4'h2);   // FB   0x2xxx_xxxx

  logic        dc_req, dc_we;
  logic [3:0]  dc_be;
  logic [31:0] dc_addr, dc_wdata;
  logic        dc_gnt, dc_rvalid;
  logic [31:0] dc_rdata;

  // Route uncached directly to outer bus mux
  logic        mux_dreq, mux_dwe, mux_dgnt, mux_drvalid;
  logic [3:0]  mux_dbe;
  logic [31:0] mux_daddr, mux_dwdata, mux_drdata;

  logic        dcache_req, dcache_we;
  logic [3:0]  dcache_be;
  logic [31:0] dcache_addr, dcache_wdata;
  logic        dcache_gnt, dcache_rvalid;
  logic [31:0] dcache_rdata;

  logic        dcache_mreq, dcache_mwe;
  logic [3:0]  dcache_mbe;
  logic [31:0] dcache_maddr, dcache_mwdata;
  logic        dcache_mgnt, dcache_mrvalid;
  logic [31:0] dcache_mrdata;

  core u_core (
    .clk_i,
    .rst_ni,
    .instr_req_o    (c_ireq),
    .instr_addr_o   (c_iaddr),
    .instr_gnt_i    (c_ignt),
    .instr_rvalid_i (c_irvalid),
    .instr_rdata_i  (c_irdata),
    .data_req_o     (c_dreq),
    .data_we_o      (c_dwe),
    .data_be_o      (c_dbe),
    .data_addr_o    (c_daddr),
    .data_wdata_o   (c_dwdata),
    .data_gnt_i     (c_dgnt),
    .data_rvalid_i  (c_drvalid),
    .data_rdata_i   (c_drdata),
    .irq_timer_i,
    .irq_ext_i,
    .error_o
  );

  icache #(.Bypass(IBypass)) u_icache (
    .clk_i,
    .rst_ni,
    .req_i       (c_ireq),
    .addr_i      (c_iaddr),
    .gnt_o       (c_ignt),
    .rvalid_o    (c_irvalid),
    .rdata_o     (c_irdata),
    .mem_req_o   (instr_req_o),
    .mem_addr_o  (instr_addr_o),
    .mem_gnt_i   (instr_gnt_i),
    .mem_rvalid_i(instr_rvalid_i),
    .mem_rdata_i (instr_rdata_i),
    .hit_count_o (icache_hits_o),
    .miss_count_o(icache_misses_o)
  );

  // Split cached vs uncached data path (after store buffer)
  assign dcache_req   = s_req && !d_uncached;
  assign dcache_we    = s_we;
  assign dcache_be    = s_be;
  assign dcache_addr  = s_addr;
  assign dcache_wdata = s_wdata;

  dcache #(.Bypass(DBypass)) u_dcache (
    .clk_i,
    .rst_ni,
    .req_i       (dcache_req),
    .we_i        (dcache_we),
    .be_i        (dcache_be),
    .addr_i      (dcache_addr),
    .wdata_i     (dcache_wdata),
    .gnt_o       (dcache_gnt),
    .rvalid_o    (dcache_rvalid),
    .rdata_o     (dcache_rdata),
    .mem_req_o   (dcache_mreq),
    .mem_we_o    (dcache_mwe),
    .mem_be_o    (dcache_mbe),
    .mem_addr_o  (dcache_maddr),
    .mem_wdata_o (dcache_mwdata),
    .mem_gnt_i   (dcache_mgnt),
    .mem_rvalid_i(dcache_mrvalid),
    .mem_rdata_i (dcache_mrdata),
    .hit_count_o (dcache_hits_o),
    .miss_count_o(dcache_misses_o)
  );

  // Outer data mux: cache miss path OR uncached access.
  // Hold the uncached grant/rvalid path until rvalid: the store buffer drops
  // mem_req in D_WAIT, which would otherwise deselect this mux and lose rvalid.
  logic uncached_active, unc_busy_q, use_uncached;
  assign uncached_active = s_req && d_uncached;

  always_ff @(posedge clk_i) begin
    if (!rst_ni)
      unc_busy_q <= 1'b0;
    else if ((uncached_active || unc_busy_q) && data_rvalid_i)
      unc_busy_q <= 1'b0;
    else if (uncached_active && data_gnt_i && !data_rvalid_i)
      unc_busy_q <= 1'b1;
  end

  assign use_uncached = uncached_active || unc_busy_q;

  assign data_req_o   = use_uncached ? s_req   : dcache_mreq;
  assign data_we_o    = use_uncached ? s_we    : dcache_mwe;
  assign data_be_o    = use_uncached ? s_be    : dcache_mbe;
  assign data_addr_o  = use_uncached ? s_addr  : dcache_maddr;
  assign data_wdata_o = use_uncached ? s_wdata : dcache_mwdata;

  assign dcache_mgnt    = use_uncached ? 1'b0 : data_gnt_i;
  assign dcache_mrvalid = use_uncached ? 1'b0 : data_rvalid_i;
  assign dcache_mrdata  = data_rdata_i;

  assign s_gnt    = use_uncached ? data_gnt_i    : dcache_gnt;
  assign s_rvalid = use_uncached ? data_rvalid_i : dcache_rvalid;
  assign s_rdata  = use_uncached ? data_rdata_i  : dcache_rdata;

endmodule
