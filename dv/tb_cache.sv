`timescale 1ns/100ps

// Exercise core_cached with multi-cycle "DDR" memory model.
// Each accepted request draws a fresh latency in [DDR_LAT_MIN, DDR_LAT_MAX].
module tb_cache
  import core_pkg::*;
();

  localparam int unsigned DDR_LAT_MIN = 8;
  localparam int unsigned DDR_LAT_MAX = 100;
  localparam int unsigned MemWords = 4096;

  logic clk_i = 1;
  logic rst_ni;

  logic        ireq, ignt, irvalid;
  logic [31:0] iaddr, irdata;
  logic        dreq, dwe, dgnt, drvalid;
  logic [3:0]  dbe;
  logic [31:0] daddr, dwdata, drdata;
  logic        error;
  logic [31:0] ihit, imiss, dhit, dmiss;

  logic [31:0] mem [MemWords];
  logic [31:0] fb_word;
  logic        mem_init_done = 1'b0;

  // Latency stats (sim-only)
  int unsigned i_lat_sum, d_lat_sum, i_lat_n, d_lat_n;
  int unsigned i_lat_min_seen, i_lat_max_seen;
  int unsigned d_lat_min_seen, d_lat_max_seen;

  function automatic int unsigned idx(logic [31:0] a);
    return a[13:2];
  endfunction

  function automatic logic [31:0] enc_i(logic [6:0] op, logic [2:0] f3,
                                       logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
    return {imm, rs1, f3, rd, op};
  endfunction

  function automatic logic [31:0] enc_u(logic [6:0] op, logic [4:0] rd, logic [19:0] imm20);
    return {imm20, rd, op};
  endfunction

  function automatic logic [31:0] enc_s(logic [2:0] f3, logic [4:0] rs1, logic [4:0] rs2,
                                       logic [11:0] imm);
    return {imm[11:5], rs2, rs1, f3, imm[4:0], 7'b0100011};
  endfunction

  function automatic int unsigned rand_ddr_lat();
    return $urandom_range(DDR_LAT_MIN, DDR_LAT_MAX);
  endfunction

  logic        i_busy, d_busy;
  logic [7:0]  i_cnt, d_cnt; // holds up to 100
  logic [31:0] i_addr_q, d_addr_q, d_wdata_q;
  logic [31:0] i_last_addr, d_last_addr;
  logic        i_last_ok, d_last_ok;
  logic [3:0]  d_be_q;
  logic        d_we_q;

  always_ff @(posedge clk_i) begin
    int unsigned lat;
    if (!rst_ni) begin
      i_busy <= 0; d_busy <= 0;
      i_cnt <= 0; d_cnt <= 0;
      ignt <= 0; irvalid <= 0; irdata <= 0;
      dgnt <= 0; drvalid <= 0; drdata <= 0;
      i_lat_sum <= 0; d_lat_sum <= 0;
      i_lat_n <= 0; d_lat_n <= 0;
      i_lat_min_seen <= DDR_LAT_MAX;
      i_lat_max_seen <= DDR_LAT_MIN;
      d_lat_min_seen <= DDR_LAT_MAX;
      d_lat_max_seen <= DDR_LAT_MIN;
      i_last_ok <= 0;
      d_last_ok <= 0;
      if (!mem_init_done) begin
        for (int i = 0; i < MemWords; i++)
          mem[i] <= 32'h0000_0013;
        // Directed D$: store→load hit, dirty evict, uncached FB store.
        // x1 = 0xA5A5A5A5
        mem[0]  <= enc_u(7'b0110111, 5'd1, 20'hA5A5A);
        mem[1]  <= enc_i(7'b0010011, 3'b000, 5'd1, 5'd1, 12'h5A5);
        // x2 = 0x80001000
        mem[2]  <= enc_u(7'b0110111, 5'd2, 20'h80001);
        mem[3]  <= enc_s(3'b010, 5'd2, 5'd1, 12'd0);                 // sw x1,0(x2)
        mem[4]  <= enc_i(7'b0000011, 3'b010, 5'd3, 5'd2, 12'd0);     // lw x3,0(x2)
        // x4 = 0x80001800 (same D$ set, different tag): 0x80002000 - 2048
        mem[5]  <= enc_u(7'b0110111, 5'd4, 20'h80002);
        mem[6]  <= enc_i(7'b0010011, 3'b000, 5'd4, 5'd4, 12'h800);
        mem[7]  <= enc_s(3'b010, 5'd4, 5'd1, 12'd0);                 // sw x1,0(x4)
        // x5 = 0x80002000 (third line in set → dirty evict)
        mem[8]  <= enc_u(7'b0110111, 5'd5, 20'h80002);
        mem[9]  <= enc_s(3'b010, 5'd5, 5'd1, 12'd0);                 // sw x1,0(x5)
        mem[10] <= enc_i(7'b0000011, 3'b010, 5'd6, 5'd2, 12'd0);     // lw x6,0(x2)
        // Uncached FB 0x20000000
        mem[11] <= enc_u(7'b0110111, 5'd7, 20'h20000);
        mem[12] <= enc_s(3'b010, 5'd7, 5'd1, 12'd0);                 // sw x1,0(x7)
        mem[13] <= enc_i(7'b0000011, 3'b010, 5'd8, 5'd2, 12'd0);     // lw x8,0(x2)
        mem[14] <= 32'h00000063; // BEQ x0,x0,0
        fb_word <= '0;
        mem_init_done <= 1'b1;
      end
    end else begin
      ignt <= 0; irvalid <= 0;
      dgnt <= 0; drvalid <= 0;

      if (!i_busy && ireq) begin
        if (i_last_ok && (iaddr[31:5] == i_last_addr[31:5]) && (iaddr == i_last_addr + 32'd4))
          lat = 1;
        else
          lat = rand_ddr_lat();
        ignt <= 1;
        i_busy <= 1;
        i_cnt <= lat[7:0];
        i_addr_q <= iaddr;
        i_lat_sum <= i_lat_sum + lat;
        i_lat_n <= i_lat_n + 1;
        if (lat < i_lat_min_seen) i_lat_min_seen <= lat;
        if (lat > i_lat_max_seen) i_lat_max_seen <= lat;
      end else if (i_busy) begin
        if (i_cnt == 0) begin
          irvalid <= 1;
          irdata <= mem[idx(i_addr_q)];
          i_busy <= 0;
          i_last_addr <= i_addr_q;
          i_last_ok <= 1;
        end else i_cnt <= i_cnt - 1;
      end

      if (!d_busy && dreq) begin
        if (!dwe && d_last_ok && (daddr[31:5] == d_last_addr[31:5]) && (daddr == d_last_addr + 32'd4))
          lat = 1;
        else
          lat = rand_ddr_lat();
        dgnt <= 1;
        d_busy <= 1;
        d_cnt <= lat[7:0];
        d_addr_q <= daddr;
        d_wdata_q <= dwdata;
        d_be_q <= dbe;
        d_we_q <= dwe;
        d_lat_sum <= d_lat_sum + lat;
        d_lat_n <= d_lat_n + 1;
        if (lat < d_lat_min_seen) d_lat_min_seen <= lat;
        if (lat > d_lat_max_seen) d_lat_max_seen <= lat;
      end else if (d_busy) begin
        if (d_cnt == 0) begin
          drvalid <= 1;
          if (d_addr_q[31:28] == 4'h1) begin
            drdata <= 32'h1; // UART/MMIO: TX ready
          end else if (d_addr_q[31:28] == 4'h2) begin
            if (d_we_q) begin
              if (d_be_q[0]) fb_word[7:0]   <= d_wdata_q[7:0];
              if (d_be_q[1]) fb_word[15:8]  <= d_wdata_q[15:8];
              if (d_be_q[2]) fb_word[23:16] <= d_wdata_q[23:16];
              if (d_be_q[3]) fb_word[31:24] <= d_wdata_q[31:24];
              drdata <= d_wdata_q;
            end else
              drdata <= fb_word;
          end else if (d_we_q) begin
            if (d_be_q[0]) mem[idx(d_addr_q)][7:0]   <= d_wdata_q[7:0];
            if (d_be_q[1]) mem[idx(d_addr_q)][15:8]  <= d_wdata_q[15:8];
            if (d_be_q[2]) mem[idx(d_addr_q)][23:16] <= d_wdata_q[23:16];
            if (d_be_q[3]) mem[idx(d_addr_q)][31:24] <= d_wdata_q[31:24];
            drdata <= d_wdata_q;
          end else begin
            drdata <= mem[idx(d_addr_q)];
          end
          d_busy <= 0;
          d_last_addr <= d_addr_q;
          d_last_ok <= 1;
        end else d_cnt <= d_cnt - 1;
      end
    end
  end

  core_cached #(
    .IBypass(1'b0),
    .DBypass(1'b0)
  ) u_dut (
    .clk_i,
    .rst_ni,
    .instr_req_o    (ireq),
    .instr_addr_o   (iaddr),
    .instr_gnt_i    (ignt),
    .instr_rvalid_i (irvalid),
    .instr_rdata_i  (irdata),
    .data_req_o     (dreq),
    .data_we_o      (dwe),
    .data_be_o      (dbe),
    .data_addr_o    (daddr),
    .data_wdata_o   (dwdata),
    .data_gnt_i     (dgnt),
    .data_rvalid_i  (drvalid),
    .data_rdata_i   (drdata),
    .irq_timer_i    (1'b0),
    .irq_ext_i      (1'b0),
    .error_o        (error),
    .icache_hits_o  (ihit),
    .icache_misses_o(imiss),
    .dcache_hits_o  (dhit),
    .dcache_misses_o(dmiss)
  );

  initial forever #1 clk_i = ~clk_i;

  initial begin
    rst_ni = 0;
    repeat (4) @(posedge clk_i);
    rst_ni = 1;
    // Longer run: random DDR can be up to 100 cycles per miss
    repeat (20000) @(posedge clk_i);

    $display("CACHE STATS I hit=%0d miss=%0d  D hit=%0d miss=%0d", ihit, imiss, dhit, dmiss);
    if (i_lat_n != 0)
      $display("DDR I-lat n=%0d min=%0d max=%0d avg=%0d (range %0d..%0d)",
               i_lat_n, i_lat_min_seen, i_lat_max_seen, i_lat_sum / i_lat_n,
               DDR_LAT_MIN, DDR_LAT_MAX);
    if (d_lat_n != 0)
      $display("DDR D-lat n=%0d min=%0d max=%0d avg=%0d (range %0d..%0d)",
               d_lat_n, d_lat_min_seen, d_lat_max_seen, d_lat_sum / d_lat_n,
               DDR_LAT_MIN, DDR_LAT_MAX);
    if (imiss == 0)
      $fatal(1, "Expected at least one I$ miss against DDR");
    if (ihit == 0)
      $fatal(1, "Expected I$ hits after 32 B line fill");
    if (i_lat_n != 0 && i_lat_max_seen > DDR_LAT_MAX)
      $fatal(1, "I DDR latency out of range");
    if (u_dut.u_core.registers_dbg[3] != 32'hA5A5A5A5)
      $fatal(1, "store→load hit failed x3=%h", u_dut.u_core.registers_dbg[3]);
    if (u_dut.u_core.registers_dbg[6] != 32'hA5A5A5A5)
      $fatal(1, "dirty evict reload failed x6=%h", u_dut.u_core.registers_dbg[6]);
    if (u_dut.u_core.registers_dbg[8] != 32'hA5A5A5A5)
      $fatal(1, "post-FB cached load failed x8=%h", u_dut.u_core.registers_dbg[8]);
    if (fb_word != 32'hA5A5A5A5)
      $fatal(1, "uncached FB store failed fb=%h", fb_word);
    if (dhit == 0)
      $fatal(1, "Expected D$ hits");
    if (dmiss == 0)
      $fatal(1, "Expected D$ misses (write-allocate)");

    $display("PASS: tb_cache line-fill / WB+WA / uncached FB");
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule
