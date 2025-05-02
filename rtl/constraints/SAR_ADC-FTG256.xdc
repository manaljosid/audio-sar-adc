## SAR_ADC-FTG256.xdc
## Constraints file for the custom PCB for the ADC evaluation

## General config
set_property CFGBVS VCCO                               [current_design]
set_property CONFIG_VOLTAGE 3.3                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50            [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]

## Clock signal
set_property -dict {LOC D4  IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

## Clock signal
set_property -dict {LOC F5  IOSTANDARD LVCMOS33} [get_ports adc_clk]
create_clock -period 10.173 -name adc_clk [get_ports adc_clk]

## Clock domain crossing constraints
set_clock_groups -group [get_clocks -include_generated_clocks clk] -group [get_clocks -include_generated_clocks adc_clk] -asynchronous

## Reset button
set_property -dict {LOC C1  IOSTANDARD LVCMOS33} [get_ports reset_n]

set_false_path -from [get_ports {reset_n}]
set_input_delay 0 [get_ports {reset_n}]

## Extra ouputs
set_property -dict {LOC T13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[0]}]
set_property -dict {LOC T14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[1]}]
set_property -dict {LOC T15 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[2]}]
set_property -dict {LOC R15 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[3]}]
set_property -dict {LOC R16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[4]}]
set_property -dict {LOC P15 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[5]}]
set_property -dict {LOC P16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[6]}]
set_property -dict {LOC N16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports {extra[7]}]

## Ethernet MII PHY
set_property -dict {LOC E12 IOSTANDARD LVCMOS33} [get_ports phy_rx_clk]
set_property -dict {LOC A12 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[0]}]
set_property -dict {LOC A13 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[1]}]
set_property -dict {LOC B14 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[2]}]
set_property -dict {LOC A14 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[3]}]
set_property -dict {LOC B10 IOSTANDARD LVCMOS33} [get_ports phy_rx_dv]
set_property -dict {LOC B11 IOSTANDARD LVCMOS33} [get_ports phy_rx_er]

set_property -dict {LOC D13 IOSTANDARD LVCMOS33} [get_ports phy_tx_clk]
set_property -dict {LOC A15 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[0]}]
set_property -dict {LOC B16 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[1]}]
set_property -dict {LOC C16 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[2]}]
set_property -dict {LOC D16 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {phy_txd[3]}]
set_property -dict {LOC B15 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports phy_tx_en]

set_property -dict {LOC B12 IOSTANDARD LVCMOS33} [get_ports phy_col]
set_property -dict {LOC A10 IOSTANDARD LVCMOS33} [get_ports phy_crs]
set_property -dict {LOC E13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_ref_clk]
set_property -dict {LOC A8  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_reset_n]
set_property -dict {LOC B9  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_mdio]
set_property -dict {LOC A9  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_mdc]

create_clock -period 40.000 -name phy_rx_clk [get_ports phy_rx_clk]
create_clock -period 40.000 -name phy_tx_clk [get_ports phy_tx_clk]

set_output_delay -clock phy_tx_clk -max 11 [get_ports phy_txd]
set_output_delay -clock phy_tx_clk -max 11 [get_ports phy_tx_en]

set_output_delay -clock phy_tx_clk -min 1 [get_ports phy_txd] -add_delay
set_output_delay -clock phy_tx_clk -min 1 [get_ports phy_tx_en] -add_delay

set_input_delay -clock phy_rx_clk -min 9 [get_ports phy_rxd]
set_input_delay -clock phy_rx_clk -min 9 [get_ports phy_rx_dv]
set_input_delay -clock phy_rx_clk -min 9 [get_ports phy_rx_er]

set_input_delay -clock phy_rx_clk -max 31 [get_ports phy_rxd] -add_delay
set_input_delay -clock phy_rx_clk -max 31 [get_ports phy_rx_dv] -add_delay
set_input_delay -clock phy_rx_clk -max 31 [get_ports phy_rx_er] -add_delay

set_false_path -to [get_ports {phy_ref_clk phy_reset_n}]
set_output_delay 0 [get_ports {phy_ref_clk phy_reset_n}]

set_clock_groups -group [get_clocks -include_generated_clocks clk] \
                 -group [get_clocks -include_generated_clocks phy_rx_clk] \
                 -group [get_clocks -include_generated_clocks phy_tx_clk] -asynchronous

#set_false_path -to [get_ports {phy_mdio phy_mdc}]
#set_output_delay 0 [get_ports {phy_mdio phy_mdc}]
#set_false_path -from [get_ports {phy_mdio}]
#set_input_delay 0 [get_ports {phy_mdio}]

# ADC/DAC signals
set_property -dict {LOC M16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports eoc_1]
set_property -dict {LOC M14 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports eoc_2]

set_property -dict {LOC M1  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports dsm1]
set_property -dict {LOC P1  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports dsm2]
set_property -dict {LOC T2  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports dsm3]
set_property -dict {LOC T3  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports dsm4]
set_property -dict {LOC N1  IOSTANDARD LVCMOS33} [get_ports comp_1]
set_property -dict {LOC R1  IOSTANDARD LVCMOS33} [get_ports comp_2]

set_input_delay 0 [get_ports {comp_1}]
set_input_delay 0 [get_ports {comp_2}]