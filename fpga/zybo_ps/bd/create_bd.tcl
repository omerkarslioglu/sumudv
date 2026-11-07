# Create Block Design: Zynq PS + DDR + HP0 (PL master) + GPIO cpu_run (PS GP0)
# Sourced from create_project.tcl with project already open.

set bd_name design_1

create_bd_design $bd_name
current_bd_design $bd_name

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

set has_board 0
if {[llength [get_board_parts -quiet digilentinc.com:zybo-z7-20*]] > 0} {
  set has_board 1
  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    [get_bd_cells processing_system7_0]
} else {
  puts "WARN: zybo-z7-20 board files missing — DDR preset may be incomplete"
  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable"} \
    [get_bd_cells processing_system7_0]
}

set_property -dict [list \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50} \
  CONFIG.PCW_EN_CLK0_PORT {1} \
  CONFIG.PCW_EN_RST0_PORT {1} \
  CONFIG.PCW_USE_S_AXI_HP0 {1} \
  CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} \
  CONFIG.PCW_USE_M_AXI_GP0 {1} \
] [get_bd_cells processing_system7_0]

# ---- AXI GPIO: cpu_run (1 = release RISC-V reset) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_cpu
set_property -dict [list \
  CONFIG.C_GPIO_WIDTH {1} \
  CONFIG.C_ALL_OUTPUTS {1} \
  CONFIG.C_DOUT_DEFAULT {0x00000000} \
] [get_bd_cells axi_gpio_cpu]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
  -config {Clk_master {/processing_system7_0/FCLK_CLK0} Clk_slave {/processing_system7_0/FCLK_CLK0} \
           Clk_xbar {/processing_system7_0/FCLK_CLK0} Master {/processing_system7_0/M_AXI_GP0} \
           Slave {/axi_gpio_cpu/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}} \
  [get_bd_intf_pins axi_gpio_cpu/S_AXI]

# proc_sys_reset created by GP0 automation
set rst_cell [get_bd_cells -quiet rst_ps7_0_50M]
if {[llength $rst_cell] == 0} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_50M
  connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins rst_ps7_0_50M/slowest_sync_clk]
  connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_50M/ext_reset_in]
}

# ---- External AXI4-Lite → HP0 ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_hp
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] [get_bd_cells axi_ic_hp]

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
set_property -dict [list \
  CONFIG.PROTOCOL {AXI4LITE} \
  CONFIG.ADDR_WIDTH {32} \
  CONFIG.DATA_WIDTH {32} \
  CONFIG.HAS_BURST {0} \
  CONFIG.HAS_CACHE {0} \
  CONFIG.HAS_LOCK {0} \
  CONFIG.HAS_PROT {1} \
  CONFIG.HAS_QOS {0} \
  CONFIG.HAS_REGION {0} \
  CONFIG.HAS_WSTRB {1} \
  CONFIG.HAS_BRESP {1} \
  CONFIG.HAS_RRESP {1} \
  CONFIG.FREQ_HZ {50000000} \
] [get_bd_intf_ports S_AXI]

connect_bd_intf_net [get_bd_intf_ports S_AXI] [get_bd_intf_pins axi_ic_hp/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_ic_hp/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_ic_hp/ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_ic_hp/S00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_ic_hp/M00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]

connect_bd_net [get_bd_pins rst_ps7_0_50M/interconnect_aresetn] [get_bd_pins axi_ic_hp/ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] [get_bd_pins axi_ic_hp/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] [get_bd_pins axi_ic_hp/M00_ARESETN]

create_bd_port -dir O -type clk FCLK_CLK0
create_bd_port -dir O -type rst FCLK_RESET0_N
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_ports FCLK_CLK0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_ports FCLK_RESET0_N]
set_property CONFIG.FREQ_HZ 50000000 [get_bd_ports FCLK_CLK0]
set_property CONFIG.ASSOCIATED_RESET {FCLK_RESET0_N} [get_bd_ports FCLK_CLK0]
set_property CONFIG.ASSOCIATED_BUSIF {S_AXI} [get_bd_ports FCLK_CLK0]

create_bd_port -dir O -from 0 -to 0 cpu_run
connect_bd_net [get_bd_pins axi_gpio_cpu/gpio_io_o] [get_bd_ports cpu_run]

assign_bd_address
validate_bd_design
save_bd_design

# GPIO base for XSCT (PS GP0 view)
set gaddr 0x41200000
set gpio_segs [get_bd_addr_segs -of_objects [get_bd_intf_pins axi_gpio_cpu/S_AXI]]
foreach s $gpio_segs {
  set off [get_property OFFSET $s]
  if {$off ne ""} {
    set gaddr $off
    puts "INFO: axi_gpio_cpu segment $s OFFSET=$off"
  }
}
set out_dir [file join [file dirname [file dirname [info script]]] bitstream]
file mkdir $out_dir
set fd [open [file join $out_dir gpio_cpu_run_addr.txt] w]
if {[string is integer -strict $gaddr]} {
  puts $fd [format "0x%08X" $gaddr]
} else {
  puts $fd $gaddr
}
close $fd
puts "INFO: wrote gpio_cpu_run_addr.txt = $gaddr"

puts "INFO: Board preset used=$has_board"
puts "INFO: Block design $bd_name saved"
