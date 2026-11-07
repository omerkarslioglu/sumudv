`timescale 1ns/100ps

// Zybo Z7-20 PL bring-up top (bitstream target #1).
// Soft RISC-V + 64 KiB BRAM + UART TX (Pmod JB) + 4 LEDs. No PS/DDR/HDMI yet.
module fpga_top #(
  parameter int unsigned BramWords = 16384,
  parameter string       MemInit   = "firmware.mem"
) (
  input  logic       clk_125_i,
  input  logic       btn_reset_i, // active-high BTN0
  output logic [3:0] led_o,
  output logic       uart_tx_o
);

  // ---- Clock / reset ----
  logic clk_i, mmcm_locked, rst_ni;
  logic [3:0] rst_sync;

  clk_wiz_50 u_clk (
    .clk_125_i (clk_125_i),
    .rst_i     (btn_reset_i),
    .clk_50_o  (clk_i),
    .locked_o  (mmcm_locked)
  );

  always_ff @(posedge clk_i or posedge btn_reset_i) begin
    if (btn_reset_i)
      rst_sync <= 4'b0000;
    else if (!mmcm_locked)
      rst_sync <= 4'b0000;
    else
      rst_sync <= {rst_sync[2:0], 1'b1};
  end
  assign rst_ni = rst_sync[3];

  // ---- Core ----
  logic        ireq, ignt, irvalid;
  logic [31:0] iaddr, irdata;
  logic        dreq, dwe, dgnt, drvalid;
  logic [3:0]  dbe;
  logic [31:0] daddr, dwdata, drdata;
  logic        error;

  logic        mem_req, uart_req, gpio_req;
  logic        mem_gnt, uart_gnt, gpio_gnt;
  logic        mem_rvalid, uart_rvalid, gpio_rvalid;
  logic [31:0] mem_rdata, uart_rdata, gpio_rdata;

  core u_core (
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
    .error_o        (error)
  );

  // Address decode (data port)
  //   0x1000_0000 UART
  //   0x1000_2000 GPIO LEDs
  //   else        BRAM (boot image window mirrors low address bits)
  logic is_uart, is_gpio;
  assign is_uart = (daddr[31:16] == 16'h1000) && (daddr[15:12] == 4'h0);
  assign is_gpio = (daddr[31:16] == 16'h1000) && (daddr[15:12] == 4'h2);

  assign mem_req  = dreq && !is_uart && !is_gpio;
  assign uart_req = dreq && is_uart;
  assign gpio_req = dreq && is_gpio;

  always_comb begin
    if (is_uart) begin
      dgnt    = uart_gnt;
      drvalid = uart_rvalid;
      drdata  = uart_rdata;
    end else if (is_gpio) begin
      dgnt    = gpio_gnt;
      drvalid = gpio_rvalid;
      drdata  = gpio_rdata;
    end else begin
      dgnt    = mem_gnt;
      drvalid = mem_rvalid;
      drdata  = mem_rdata;
    end
  end

  fpga_bram #(
    .DepthWords (BramWords),
    .InitFile   (MemInit)
  ) u_bram (
    .clk_i,
    .rst_ni,
    .i_req_i    (ireq),
    .i_addr_i   (iaddr),
    .i_gnt_o    (ignt),
    .i_rvalid_o (irvalid),
    .i_rdata_o  (irdata),
    .d_req_i    (mem_req),
    .d_we_i     (dwe),
    .d_be_i     (dbe),
    .d_addr_i   (daddr),
    .d_wdata_i  (dwdata),
    .d_gnt_o    (mem_gnt),
    .d_rvalid_o (mem_rvalid),
    .d_rdata_o  (mem_rdata)
  );

  uart_tx #(
    .ClkHz (50_000_000),
    .Baud  (115_200)
  ) u_uart (
    .clk_i,
    .rst_ni,
    .req_i     (uart_req),
    .we_i      (dwe),
    .be_i      (dbe),
    .addr_i    (daddr),
    .wdata_i   (dwdata),
    .gnt_o     (uart_gnt),
    .rvalid_o  (uart_rvalid),
    .rdata_o   (uart_rdata),
    .uart_tx_o (uart_tx_o)
  );

  gpio_leds u_gpio (
    .clk_i,
    .rst_ni,
    .req_i    (gpio_req),
    .we_i     (dwe),
    .be_i     (dbe),
    .addr_i   (daddr),
    .wdata_i  (dwdata),
    .gnt_o    (gpio_gnt),
    .rvalid_o (gpio_rvalid),
    .rdata_o  (gpio_rdata),
    .led_o    (led_o)
  );

  // Keep error visible for debug (tie into unused so it is not optimized away silently)
  logic unused_error;
  assign unused_error = error;

endmodule
