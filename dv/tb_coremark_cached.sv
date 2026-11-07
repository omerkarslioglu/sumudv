`timescale 1ns/100ps

// CoreMark through L1 I$/D$ + store buffer (split-phase outer mem).
module tb_coremark_cached
  import core_pkg::*;
();

  import "DPI-C" function void dpi_mem_init(input string hex_path);
  import "DPI-C" function void dpi_mem_write(input int addr, input int data, input int be);
  import "DPI-C" function int  dpi_mem_read(input int addr);
  import "DPI-C" function int  dpi_uart_contains(input string needle);

  logic clk_i = 1;
  logic rst_ni = 0;

  logic        ireq, ignt, irvalid;
  logic [31:0] iaddr, irdata;
  logic        dreq, dwe, dgnt, drvalid;
  logic [3:0]  dbe;
  logic [31:0] daddr, dwdata, drdata;
  logic        error;
  logic [31:0] ihit, imiss, dhit, dmiss;

  bit mem_ready;
  logic        i_busy, d_busy, d_we_q;
  logic [31:0] i_addr_q, d_addr_q, d_wdata_q;
  logic [3:0]  d_be_q;

  initial begin
    dpi_mem_init("../sw/coremark_eembc/build/coremark.hex");
    mem_ready = 1'b1;
  end

  // Split-phase outer mem (gnt, then rvalid). Cache drops req in WAIT so beats
  // are not sampled twice against a stale address.
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      i_busy <= 1'b0;
      d_busy <= 1'b0;
      ignt <= 1'b0;
      irvalid <= 1'b0;
      dgnt <= 1'b0;
      drvalid <= 1'b0;
    end else begin
      ignt <= 1'b0;
      irvalid <= 1'b0;
      dgnt <= 1'b0;
      drvalid <= 1'b0;
      if (!i_busy && ireq) begin
        ignt     <= 1'b1;
        i_busy   <= 1'b1;
        i_addr_q <= iaddr;
      end else if (i_busy) begin
        irvalid <= 1'b1;
        irdata  <= dpi_mem_read(int'(i_addr_q));
        i_busy  <= 1'b0;
      end
      if (!d_busy && dreq) begin
        dgnt      <= 1'b1;
        d_busy    <= 1'b1;
        d_addr_q  <= daddr;
        d_wdata_q <= dwdata;
        d_be_q    <= dbe;
        d_we_q    <= dwe;
      end else if (d_busy) begin
        drvalid <= 1'b1;
        if (d_we_q)
          dpi_mem_write(int'(d_addr_q), int'(d_wdata_q), int'(d_be_q));
        drdata <= d_we_q ? d_wdata_q : dpi_mem_read(int'(d_addr_q));
        d_busy <= 1'b0;
      end
    end
  end

  core_cached #(
    .IBypass(1'b0),
    .DBypass(1'b0)
  ) u_core (
    .clk_i, .rst_ni,
    .instr_req_o(ireq), .instr_addr_o(iaddr),
    .instr_gnt_i(ignt), .instr_rvalid_i(irvalid), .instr_rdata_i(irdata),
    .data_req_o(dreq), .data_we_o(dwe), .data_be_o(dbe),
    .data_addr_o(daddr), .data_wdata_o(dwdata),
    .data_gnt_i(dgnt), .data_rvalid_i(drvalid), .data_rdata_i(drdata),
    .irq_timer_i(1'b0), .irq_ext_i(1'b0), .error_o(error),
    .icache_hits_o(ihit), .icache_misses_o(imiss),
    .dcache_hits_o(dhit), .dcache_misses_o(dmiss)
  );

  initial forever #1 clk_i = ~clk_i;

  initial begin
    logic [31:0] tohost, cycles, iters, cm_x100;
    longint unsigned wall;
    wait (mem_ready);
    rst_ni = 0;
    repeat (8) @(posedge clk_i);
    rst_ni = 1;

    wall = 0;
    forever begin
      @(posedge clk_i);
      wall++;
      if (wall % 200_000 == 0)
        $display("[progress] cyc=%0d cpu_pc=%08x i$miss_addr=%08x tohost=%08x",
                 wall, u_core.u_core.pc, iaddr, dpi_mem_read(32'h800F0000));
      tohost = dpi_mem_read(32'h800F0000);
      if (tohost[31:16] == 16'hC0FE) begin
        cycles  = dpi_mem_read(32'h800F0004);
        iters   = dpi_mem_read(32'h800F0008);
        cm_x100 = dpi_mem_read(32'h800F000C);
        $display("");
        $display("======== SUMUD-V CoreMark (RTL, L1 cached) ========");
        $display("Iterations     : %0d", iters);
        $display("Cycles         : %0d  (TB wall %0d)", cycles, wall);
        $display("CoreMark/MHz   : %0d.%02d", cm_x100 / 100, cm_x100 % 100);
        $display("I$ hit=%0d miss=%0d  D$ hit=%0d miss=%0d", ihit, imiss, dhit, dmiss);
        $display("===================================================");
        if (!dpi_uart_contains("e714") ||
            !dpi_uart_contains("1fd7") ||
            !dpi_uart_contains("8e3a"))
          $fatal(1, "CoreMark CRC mismatch (expected e714 / 1fd7 / 8e3a)");
        $display("CRC list=e714 matrix=1fd7 state=8e3a OK");
        $finish;
      end
    end
  end

  initial begin
    #800_000_000;
    $display("TIMEOUT pc=%08x tohost=%08x", iaddr, dpi_mem_read(32'h800F0000));
    $fatal(1, "TIMEOUT waiting for cached CoreMark");
  end

endmodule
