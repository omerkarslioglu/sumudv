## Zybo Z7-20 minimal constraints for SUMUD-V SoC bring-up
## Adjust clocks/pins to match your BD + HDMI IP.

## 125 MHz system clock (ZYBO SYSCLK)
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports clk_i]
create_clock -add -name sys_clk -period 8.00 [get_ports clk_i]

## Pixel clock — drive from MMCM/PLL in BD; placeholder period for 25 MHz VGA-ish
# create_clock -add -name pix_clk -period 40.00 [get_ports clk_pix_i]

## Reset (btn)
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports rst_ni]

## HDMI (TMDS) — enable when using Digilent RGB2DVI / official HDMI IP
## Example pinout varies by board revision; leave commented until IP is added.
# set_property -dict { PACKAGE_PIN H17 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_p]
# set_property -dict { PACKAGE_PIN H16 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_n]

## LEDs for debug
# set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
