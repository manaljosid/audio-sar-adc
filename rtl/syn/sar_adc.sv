/**
 * @file sar_adc.sv
 * 
 * @author Mani Magnusson
 * @date   2025
 *
 * @brief SAR ADC with a delta-sigma reference DAC
 */

`default_nettype none

module sar_adc # (
    parameter int DAC_OSR = 512,
    parameter int DAC_ORDER = 1
) (
    input var logic clk,
    input var logic reset,

    input var logic comparator,

    AXIS_IF.Master code_output_if,
    
    output var logic dac_output
);
    localparam BIT_DEPTH = code_output_if.TDATA_WIDTH;

    localparam int COEFF_BIT_DEPTH = 32;
    localparam int TAPS = 5;

    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) dac_output_if();

    sar_fsm # (
        .BIT_DEPTH(BIT_DEPTH),
        .DAC_OSR(DAC_OSR)
    ) sar_fsm_inst (
        .clk(clk),
        .reset(reset),

        .comparator(comparator),

        .adc_code_output_if(code_output_if),
        .reference_dac_output_if(dac_output_if)
    );

    generate
        if (DAC_ORDER == 1) begin
            dsm1 # () dsm_inst (
                .clk(clk),
                .reset(reset),
                
                .axis_data_in_if(dac_output_if),
                .out(dac_output)
            );
        end else if (DAC_ORDER == 2) begin
            dsm2 # () dsm_inst (
                .clk(clk),
                .reset(reset),
                
                .axis_data_in_if(dac_output_if),
                .out(dac_output)
            );
        end else begin
            $error("Error in %m, DAC_ORDER out of range");
        end
    endgenerate
endmodule

`default_nettype wire