`timescale 1ns/100ps

// Ideal combo-grant BRAM + DPI memory (cycle-accurate stores visible to loads).
module tb_coremark
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

  bit mem_ready;

  initial begin
    dpi_mem_init("../sw/coremark_eembc/build/coremark.hex");
    mem_ready = 1'b1;
  end

  assign ignt    = ireq;
  assign irvalid = ireq;
  assign dgnt    = dreq;
  assign drvalid = dreq;

  always_comb begin
    irdata = 32'h0000_0013;
    if (ireq)
      irdata = dpi_mem_read(int'(iaddr));
    drdata = 32'h0;
    if (dreq && !dwe)
      drdata = dpi_mem_read(int'(daddr));
  end

  always @(negedge clk_i) begin
    if (rst_ni && dreq && dwe && dgnt)
      dpi_mem_write(int'(daddr), int'(dwdata), int'(dbe));
  end

  core u_core (
    .clk_i, .rst_ni,
    .instr_req_o(ireq), .instr_addr_o(iaddr),
    .instr_gnt_i(ignt), .instr_rvalid_i(irvalid), .instr_rdata_i(irdata),
    .data_req_o(dreq), .data_we_o(dwe), .data_be_o(dbe),
    .data_addr_o(daddr), .data_wdata_o(dwdata),
    .data_gnt_i(dgnt), .data_rvalid_i(drvalid), .data_rdata_i(drdata),
    .irq_timer_i(1'b0), .irq_ext_i(1'b0), .error_o(error)
  );

  initial forever #1 clk_i = ~clk_i;

  initial begin
    logic [31:0] tohost, cycles, iters, cm_x100;
    longint unsigned wall;
    wait (mem_ready);
    rst_ni = 0;
    repeat (4) @(posedge clk_i);
    rst_ni = 1;

    wall = 0;
    forever begin
      @(posedge clk_i);
      wall++;
      tohost = dpi_mem_read(32'h800F0000);
      if (tohost[31:16] == 16'hC0FE) begin
        cycles  = dpi_mem_read(32'h800F0004);
        iters   = dpi_mem_read(32'h800F0008);
        cm_x100 = dpi_mem_read(32'h800F000C);
        $display("");
        $display("======== SUMUD-V CoreMark (RTL, ideal BRAM) ========");
        $display("Iterations     : %0d", iters);
        $display("Cycles         : %0d  (TB wall %0d)", cycles, wall);
        $display("CoreMark/MHz   : %0d.%02d", cm_x100 / 100, cm_x100 % 100);
        if (iters != 0 && cycles != 0) begin
          longint unsigned score_x100;
          score_x100 = (iters * 64'd5_000_000_000) / cycles;
          $display("CoreMark@50MHz : %0d.%02d", score_x100 / 100, score_x100 % 100);
        end
        $display("====================================================");
        $display("Note: Official EEMBC claims need >=10s wall-clock;");
        $display("      CoreMark/MHz from mcycle is the fair metric here.");
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
    #400_000_000;
    $display("TIMEOUT pc=%08x tohost=%08x", iaddr, dpi_mem_read(32'h800F0000));
    $fatal(1, "TIMEOUT waiting for CoreMark");
  end

endmodule
