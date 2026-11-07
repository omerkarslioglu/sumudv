## Digilent Zybo Z7-20 (xc7z020clg400-1) — SUMUD-V PL bring-up
## https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual

## 125 MHz system clock
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_125_i]
create_clock -period 8.000 -name clk_125 [get_ports clk_125_i]

## BTN0 — active-high reset
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports btn_reset_i]

## LEDs LD0..LD3
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led_o[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led_o[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led_o[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led_o[3]}]

## UART TX on Pmod JB pin 1 (jb[0] = V8) — 3.3 V USB-UART adapter: GND + RX←uart_tx
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports uart_tx_o]

## Bitstream / config (JTAG bring-up; SPI_BUSWIDTH only if using QSPI boot)
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

