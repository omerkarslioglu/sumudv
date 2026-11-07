`timescale 1ns/100ps

// 4-entry posted store queue. Loads drain the queue first (no forwarding).
module store_buffer
  import core_pkg::*;
(
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
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [3:0]  mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wdata_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [31:0] mem_rdata_i
);

  localparam int unsigned Depth = 4;
  localparam int unsigned PtrW  = $clog2(Depth);

  logic [31:0] a_q  [Depth];
  logic [31:0] d_q  [Depth];
  logic [3:0]  be_q [Depth];
  logic [PtrW-1:0] head_q, tail_q;
  logic [2:0]      count_q;

  logic empty, full;
  assign empty = (count_q == 3'd0);
  assign full  = (count_q == 3'(Depth));

  typedef enum logic { D_IDLE, D_WAIT } drain_e;
  drain_e drain_q;

  logic do_enq, do_deq, load_pass, drain_fire;
  assign do_enq     = req_i && we_i && !full;
  assign load_pass  = req_i && !we_i && empty && (drain_q == D_IDLE);
  assign drain_fire = (drain_q == D_IDLE) && !empty && mem_gnt_i;
  assign do_deq     = (drain_fire && mem_rvalid_i)
                   || ((drain_q == D_WAIT) && mem_rvalid_i);

  always_comb begin
    gnt_o    = 1'b0;
    rvalid_o = 1'b0;
    rdata_o  = mem_rdata_i;
    if (do_enq) begin
      gnt_o    = 1'b1;
      rvalid_o = 1'b1;
    end else if (load_pass) begin
      gnt_o    = mem_gnt_i;
      rvalid_o = mem_rvalid_i;
    end
  end

  always_comb begin
    mem_req_o   = 1'b0;
    mem_we_o    = 1'b0;
    mem_be_o    = 4'hF;
    mem_addr_o  = '0;
    mem_wdata_o = '0;
    if (drain_q == D_IDLE && !empty) begin
      mem_req_o   = 1'b1;
      mem_we_o    = 1'b1;
      mem_be_o    = be_q[head_q];
      mem_addr_o  = a_q[head_q];
      mem_wdata_o = d_q[head_q];
    end else if (load_pass) begin
      mem_req_o   = req_i;
      mem_we_o    = 1'b0;
      mem_be_o    = be_i;
      mem_addr_o  = addr_i;
      mem_wdata_o = wdata_i;
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      head_q  <= '0;
      tail_q  <= '0;
      count_q <= '0;
      drain_q <= D_IDLE;
      for (int i = 0; i < Depth; i++) begin
        a_q[i]  <= '0;
        d_q[i]  <= '0;
        be_q[i] <= '0;
      end
    end else begin
      if (do_enq) begin
        a_q[tail_q]  <= addr_i;
        d_q[tail_q]  <= wdata_i;
        be_q[tail_q] <= be_i;
        tail_q       <= tail_q + PtrW'(1);
      end
      if (do_deq)
        head_q <= head_q + PtrW'(1);
      count_q <= count_q + (do_enq ? 3'd1 : 3'd0) - (do_deq ? 3'd1 : 3'd0);

      unique case (drain_q)
        D_IDLE: begin
          if (drain_fire && !mem_rvalid_i)
            drain_q <= D_WAIT;
        end
        D_WAIT: begin
          if (mem_rvalid_i)
            drain_q <= D_IDLE;
        end
        default: drain_q <= D_IDLE;
      endcase
    end
  end

endmodule
