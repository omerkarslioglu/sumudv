`timescale 1ns/100ps

// 125 MHz board clock → 50 MHz PL clock (MMCME2, no Vivado IP catalog).
module clk_wiz_50 (
  input  logic clk_125_i,
  input  logic rst_i,
  output logic clk_50_o,
  output logic locked_o
);

  logic clk_fb;
  logic clk_50_u;

  MMCME2_BASE #(
    .BANDWIDTH          ("OPTIMIZED"),
    .CLKFBOUT_MULT_F    (8.0),
    .CLKFBOUT_PHASE     (0.0),
    .CLKIN1_PERIOD      (8.0),
    .CLKOUT0_DIVIDE_F   (20.0),
    .CLKOUT0_DUTY_CYCLE (0.5),
    .CLKOUT0_PHASE      (0.0),
    .DIVCLK_DIVIDE      (1),
    .REF_JITTER1        (0.010),
    .STARTUP_WAIT       ("FALSE")
  ) u_mmcm (
    .CLKIN1   (clk_125_i),
    .CLKFBIN  (clk_fb),
    .RST      (rst_i),
    .PWRDWN   (1'b0),
    .CLKFBOUT (clk_fb),
    .CLKOUT0  (clk_50_u),
    .CLKOUT0B (),
    .CLKOUT1  (),
    .CLKOUT1B (),
    .CLKOUT2  (),
    .CLKOUT2B (),
    .CLKOUT3  (),
    .CLKOUT3B (),
    .CLKOUT4  (),
    .CLKOUT5  (),
    .CLKOUT6  (),
    .CLKFBOUTB(),
    .LOCKED   (locked_o)
  );

  BUFG u_bufg (.I(clk_50_u), .O(clk_50_o));

endmodule
