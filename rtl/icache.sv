`timescale 1ns/100ps

// 2-way set-associative I$, 32 B lines, 8-beat 32-bit refill.
module icache
  import core_pkg::*;
#(
  parameter bit Bypass = 1'b1
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        req_i,
  input  logic [31:0] addr_i,
  output logic        gnt_o,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,
  output logic        mem_req_o,
  output logic [31:0] mem_addr_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [31:0] mem_rdata_i,
  output logic [31:0] hit_count_o,
  output logic [31:0] miss_count_o
);

  if (Bypass) begin : g_bypass
    assign gnt_o        = req_i && mem_gnt_i;
    assign rvalid_o     = mem_rvalid_i;
    assign rdata_o      = mem_rdata_i;
    assign mem_req_o    = req_i;
    assign mem_addr_o   = addr_i;
    assign hit_count_o  = '0;
    assign miss_count_o = '0;
  end else begin : g_cache
    localparam int unsigned Sets      = ICacheSets;
    localparam int unsigned Words     = CacheLineBytes / 4;
    localparam int unsigned OffBits   = $clog2(CacheLineBytes);
    localparam int unsigned IdxBits   = $clog2(Sets);
    localparam int unsigned TagLsb    = OffBits + IdxBits;
    localparam int unsigned WOffBits  = $clog2(Words);

    logic                 valid0_q [Sets];
    logic                 valid1_q [Sets];
    logic [31:TagLsb]     tag0_q   [Sets];
    logic [31:TagLsb]     tag1_q   [Sets];
    logic [31:0]          data0_q  [Sets][Words];
    logic [31:0]          data1_q  [Sets][Words];
    logic                 lru_q    [Sets];
    logic [31:0]          hits_q, misses_q;

    logic [IdxBits-1:0]  idx;
    logic [WOffBits-1:0] woff;
    logic                hit0, hit1, hit;
    logic [31:0]         hit_data;

    assign idx  = addr_i[TagLsb-1:OffBits];
    assign woff = addr_i[OffBits-1:2];
    assign hit0 = valid0_q[idx] && (tag0_q[idx] == addr_i[31:TagLsb]);
    assign hit1 = valid1_q[idx] && (tag1_q[idx] == addr_i[31:TagLsb]);
    assign hit  = hit0 || hit1;
    assign hit_data = hit0 ? data0_q[idx][woff] : data1_q[idx][woff];

    typedef enum logic [1:0] { IDLE, REF_REQ, REF_WAIT } state_e;
    state_e              state_q;
    logic [31:0]         addr_q;
    logic [2:0]          beat_q;
    logic [IdxBits-1:0]  idx_q;
    logic [31:TagLsb]    tag_q;
    logic                way_q;

    assign idx_q = addr_q[TagLsb-1:OffBits];
    assign tag_q = addr_q[31:TagLsb];

    assign hit_count_o  = hits_q;
    assign miss_count_o = misses_q;

    always_comb begin
      gnt_o      = 1'b0;
      rvalid_o   = 1'b0;
      rdata_o    = '0;
      mem_req_o  = 1'b0;
      mem_addr_o = {addr_q[31:OffBits], beat_q, 2'b00};
      unique case (state_q)
        IDLE: begin
          if (req_i && hit) begin
            gnt_o    = 1'b1;
            rvalid_o = 1'b1;
            rdata_o  = hit_data;
          end
        end
        REF_REQ: begin
          mem_req_o  = 1'b1;
          mem_addr_o = {addr_q[31:OffBits], beat_q, 2'b00};
        end
        REF_WAIT: mem_req_o = 1'b0;
        default: ;
      endcase
    end

    always_ff @(posedge clk_i) begin
      if (!rst_ni) begin
        state_q  <= IDLE;
        hits_q   <= '0;
        misses_q <= '0;
        beat_q   <= '0;
        addr_q   <= '0;
        way_q    <= 1'b0;
        for (int i = 0; i < Sets; i++) begin
          valid0_q[i] = 1'b0;
          valid1_q[i] = 1'b0;
          lru_q[i]    = 1'b0;
          tag0_q[i]   = '0;
          tag1_q[i]   = '0;
          for (int w = 0; w < Words; w++) begin
            data0_q[i][w] = '0;
            data1_q[i][w] = '0;
          end
        end
      end else begin
        unique case (state_q)
          IDLE: begin
            if (req_i && hit) begin
              hits_q     <= hits_q + 32'd1;
              lru_q[idx] = hit0 ? 1'b1 : 1'b0;
            end else if (req_i && !hit) begin
              misses_q <= misses_q + 32'd1;
              addr_q   <= addr_i;
              beat_q   <= '0;
              way_q    <= lru_q[idx];
              state_q  <= REF_REQ;
            end
          end
          REF_REQ: begin
            if (mem_gnt_i && mem_rvalid_i) begin
              if (!way_q) data0_q[idx_q][beat_q] = mem_rdata_i;
              else        data1_q[idx_q][beat_q] = mem_rdata_i;
              if (beat_q == 3'd7) begin
                if (!way_q) begin
                  valid0_q[idx_q] = 1'b1;
                  tag0_q[idx_q]   = tag_q;
                  lru_q[idx_q]    = 1'b1;
                end else begin
                  valid1_q[idx_q] = 1'b1;
                  tag1_q[idx_q]   = tag_q;
                  lru_q[idx_q]    = 1'b0;
                end
                state_q <= IDLE;
              end else begin
                beat_q <= beat_q + 3'd1;
              end
            end else if (mem_gnt_i) begin
              state_q <= REF_WAIT;
            end
          end
          REF_WAIT: begin
            if (mem_rvalid_i) begin
              if (!way_q) data0_q[idx_q][beat_q] = mem_rdata_i;
              else        data1_q[idx_q][beat_q] = mem_rdata_i;
              if (beat_q == 3'd7) begin
                if (!way_q) begin
                  valid0_q[idx_q] = 1'b1;
                  tag0_q[idx_q]   = tag_q;
                  lru_q[idx_q]    = 1'b1;
                end else begin
                  valid1_q[idx_q] = 1'b1;
                  tag1_q[idx_q]   = tag_q;
                  lru_q[idx_q]    = 1'b0;
                end
                state_q <= IDLE;
              end else begin
                beat_q  <= beat_q + 3'd1;
                state_q <= REF_REQ;
              end
            end
          end
          default: state_q <= IDLE;
        endcase
      end
    end
  end

endmodule
