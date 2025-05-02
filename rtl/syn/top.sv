`timescale 1ns / 1ps
`default_nettype none

module top #(
    /* PARAMETERS */
) (
    input var logic         clk,
    input var logic         adc_clk,
    input var logic         reset_n,

    output var logic        phy_ref_clk,
    input var logic         phy_rx_clk,
    input var logic [3:0]   phy_rxd,
    input var logic         phy_rx_dv,
    input var logic         phy_rx_er,
    input var logic         phy_tx_clk,
    output var logic [3:0]  phy_txd,
    output var logic        phy_tx_en,
    input var logic         phy_col,
    input var logic         phy_crs,
    output var logic        phy_reset_n,
    output var logic        phy_mdio,
    output var logic        phy_mdc,

    output var logic [7:0]  extra,

    output var logic        eoc_1,
    output var logic        eoc_2,
    output var logic        dsm1,
    output var logic        dsm2,
    output var logic        dsm3,
    output var logic        dsm4,
    input var logic         comp_1,
    input var logic         comp_2
);
    localparam int UDP_PORT_COUNT = 2;
    localparam bit [15:0] UDP_PORTS [UDP_PORT_COUNT] = {1234, 1230};

    assign extra = 8'b10101010;

    var logic clk_ibufg;
    var logic adc_clk_int;

    var logic clk_mmcm_out;
    var logic clk_int;
    var logic rst_int;

    var logic mmcm_rst = ~reset_n;
    var logic mmcm_locked;
    var logic mmcm_clkfb;

    IBUFG clk_ibufg_inst(
        .I(clk),
        .O(clk_ibufg)
    );

    IBUFG adc_clk_ibufg_inst(
        .I(adc_clk),
        .O(adc_clk_int)
    );

    var logic clk_25mhz_mmcm_out;
    var logic clk_25mhz_int;
    var logic clk_61_44mhz_mmcm_out;
    var logic clk_61_44mhz_int;

    /* MMCM Instance
     * 100 MHz input, 125 & 25 MHz output
     * PFD range: 10 MHz to 550 MHz
     * VCO range: 600 MHz to 1200 MHz
     * M = 10, D = 1 set Fvco = 1000 MHz (1 GHz, in range)
     * Divide by 8 to get 125 MHz
     * Divide by 40 to get 25 MHz
    */
    MMCME2_BASE # (
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(16),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(8),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(40),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),
        .CLKFBOUT_MULT_F(10),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(10.0),
        .STARTUP_WAIT("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    ) clk_mmcm_inst (
        .CLKIN1(clk_ibufg),
        .CLKFBIN(mmcm_clkfb),
        .RST(mmcm_rst),
        .PWRDWN('0),
        .CLKOUT0(clk_61_44mhz_mmcm_out),
        .CLKOUT0B(),
        .CLKOUT1(clk_mmcm_out),
        .CLKOUT1B(),
        .CLKOUT2(clk_25mhz_mmcm_out),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(mmcm_locked)
    );

    BUFG clk_bufg_inst (
        .I(clk_mmcm_out),
        .O(clk_int)
    );

    BUFG clk_25mhz_bufg_inst (
        .I(clk_25mhz_mmcm_out),
        .O(clk_25mhz_int)
    );

    BUFG clk_61_44mhz_bufg_inst (
        .I(clk_61_44mhz_mmcm_out),
        .O(clk_61_44mhz_int)
    );

    // Sync reset originates from the verilog-axis library in the ethernet library
    sync_reset # (
        .N(4)
    ) sync_reset_inst (
        .clk(clk_int),
        .rst(~mmcm_locked),
        .out(rst_int)
    );

    assign phy_ref_clk = clk_25mhz_int;
    assign phy_reset_n = !rst_int;

    MII_IF mii_if();
    assign mii_if.tx_clk = phy_tx_clk;
    assign phy_txd = mii_if.txd;
    assign phy_tx_en = mii_if.tx_en;
    assign mii_if.rx_clk = phy_rx_clk;
    assign mii_if.rxd = phy_rxd;
    assign mii_if.rx_dv = phy_rx_dv;
    assign mii_if.rx_er = phy_rx_er;
    assign mii_if.crs = phy_crs;
    assign mii_if.col = phy_col;

    AXIS_IF # (
        .TDATA_WIDTH(8),
        .TUSER_WIDTH(1),
        .TKEEP_ENABLE(0)
    ) mii_tx_axis_if();

    AXIS_IF # (
        .TDATA_WIDTH(8),
        .TUSER_WIDTH(1),
        .TKEEP_ENABLE(0)
    ) mii_rx_axis_if();

    var logic bad_fcs;
    var logic fifo_overflow;

    eth_mac_mii_fifo_wrapper # (
        .TARGET("XILINX")
    ) eth_mac_mii_fifo_wrapper_inst (
        .clk(clk_int),
        .reset(rst_int),
        .phy_reset(rst_int),

        .tx_axis_if(mii_tx_axis_if.Slave),
        .rx_axis_if(mii_rx_axis_if.Master),

        .mii_if(mii_if),

        .tx_error_underflow(),
        .tx_fifo_overflow(),
        .tx_fifo_bad_frame(),
        .tx_fifo_good_frame(),
      
        .rx_error_bad_frame(),
        .rx_error_bad_fcs(bad_fcs),
        .rx_fifo_overflow(fifo_overflow),
        .rx_fifo_bad_frame(),
        .rx_fifo_good_frame(),

        .cfg_ifg(8'd12),
        .cfg_tx_enable(1'b1),
        .cfg_rx_enable(1'b1)
    );

    UDP_TX_HEADER_IF udp_tx_header_if_mux [UDP_PORT_COUNT]();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if_mux [UDP_PORT_COUNT]();
    UDP_RX_HEADER_IF udp_rx_header_if_mux [UDP_PORT_COUNT]();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if_mux [UDP_PORT_COUNT]();

    eth_top # (
        .TARGET("XILINX"),
        .PORT_COUNT(UDP_PORT_COUNT),
        .PORTS(UDP_PORTS)
    ) eth_inst (
        .clk(clk_int),
        .reset(rst_int),

        .mii_tx_axis_if(mii_tx_axis_if),
        .mii_rx_axis_if(mii_rx_axis_if),

        .udp_tx_header_if_mux(udp_tx_header_if_mux),
        .udp_tx_payload_if_mux(udp_tx_payload_if_mux),
        .udp_rx_header_if_mux(udp_rx_header_if_mux),
        .udp_rx_payload_if_mux(udp_rx_payload_if_mux),

        .local_mac(48'h02_00_00_00_00_00),
        .local_ip({8'd192, 8'd168, 8'd1, 8'd128}),
        .gateway_ip({8'd192, 8'd168, 8'd1, 8'd1}),
        .subnet_mask({8'd255, 8'd255, 8'd255, 8'd0}),
        .clear_arp_cache(0)
    );

    udp_loopback # (
        .UDP_PORT(UDP_PORTS[0])
    ) udp_loopback_inst (
        .clk(clk_int),
        .reset(rst_int),
        .local_ip({8'd192, 8'd168, 8'd1, 8'd128}),
        
        .udp_tx_header_if(udp_tx_header_if_mux[0]),
        .udp_tx_payload_if(udp_tx_payload_if_mux[0]),
        .udp_rx_header_if(udp_rx_header_if_mux[0]),
        .udp_rx_payload_if(udp_rx_payload_if_mux[0])
    );

    AXIS_IF # (
        .TDATA_WIDTH(16),
        .TUSER_WIDTH(1),
        .TKEEP_ENABLE(1)
    ) udp_axis_if();
    
    AXIS_IF # (
        .TDATA_WIDTH(16),
        .TUSER_WIDTH(1),
        .TKEEP_ENABLE(1)
    ) cic_axis_if();

    AXIS_IF # (
        .TDATA_WIDTH(16),
        .TUSER_WIDTH(0),
        .TKEEP_ENABLE(0)
    ) axis_if();

    udp_axis_master # (
        .UDP_PORT(UDP_PORTS[1])
    ) udp_axis_inst (
        .clk(clk_int),
        .reset(rst_int),

        .udp_tx_header_if(udp_tx_header_if_mux[1]),
        .udp_tx_payload_if(udp_tx_payload_if_mux[1]),
        .udp_rx_header_if(udp_rx_header_if_mux[1]),
        .udp_rx_payload_if(udp_rx_payload_if_mux[1]),

        .out_axis_if(udp_axis_if)
    );

    axis_async_fifo_wrapper # (
        .DEPTH(1024)
    ) dac_sample_fifo (
        .tx_clk(adc_clk_int),
        .rx_clk(clk_int),
        .tx_reset(rst_int),
        .rx_reset(rst_int),
        .tx_axis_if(cic_axis_if),
        .rx_axis_if(udp_axis_if),
        .tx_pause_req(1'b0),
        .rx_pause_req(1'b0)
    );

    cic_upconverter # (
        .UPSAMPLING_RATIO(128),
        .ORDER(2)
    ) cic_upconverter_inst (
        .clk(clk_int),
        .reset(rst_int),
        .input_data_if(cic_axis_if),
        .output_data_if(axis_if)
    );

    dsm2 dsm2_inst (
        .clk(clk_int),
        .reset(rst_int),

        .axis_data_in_if(axis_if),
        .out(dsm1)
    );

    assign dsm2 = dsm1;
    assign dsm3 = dsm1;
    assign dsm4 = dsm1;
    
    always_ff @ (posedge clk_int) begin
        eoc_1 <= comp_1;
        eoc_2 <= comp_2;
    end
endmodule