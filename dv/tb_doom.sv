`timescale 1ns/100ps

// DOOM bring-up TB: cached core + DPI mem/FB/UART. No HDMI.
module tb_doom
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
    dpi_mem_init("../sw/doom/build/doomgeneric.hex");
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
    longint unsigned cyc;
    wait (mem_ready);
    rst_ni = 0;
    repeat (8) @(posedge clk_i);
    rst_ni = 1;
    cyc = 0;
    forever begin
      @(posedge clk_i);
      cyc++;
      if (dpi_uart_contains("SUMUD-V doomgeneric") ||
          dpi_uart_contains("IWAD") ||
          dpi_uart_contains("WAD file") ||
          dpi_uart_contains("not found")) begin
        $display("");
        $display("======== SUMUD-V DOOM (RTL, cached) ========");
        $display("UART handshake after %0d cycles", cyc);
        $display("I$ hit=%0d miss=%0d  D$ hit=%0d miss=%0d", ihit, imiss, dhit, dmiss);
        $display("============================================");
        $finish;
      end
      if (cyc % 200_000 == 0)
        $display("[progress] cyc=%0d cpu_pc=%08x", cyc, u_core.u_core.pc);
    end
  end

  initial begin
    #800_000_000;
    $display("TIMEOUT pc=%08x uart_sumud=%0d uart_iwad=%0d",
             u_core.u_core.pc, dpi_uart_contains("SUMUD-V"), dpi_uart_contains("IWAD"));
    $fatal(1, "TIMEOUT waiting for DOOM init/error UART");
  end

endmodule
