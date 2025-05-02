/**
 * @file sar_adc_tb.sv
 * 
 * @author Mani Magnusson
 * @date   2025
 * 
 * @brief SAR ADC test bench
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;
import adc_fir_coeffs::*;

module sar_adc_tb ();
    parameter int BIT_DEPTH = 16;
    parameter int DAC_OSR = 512;
    parameter int DAC_ORDER = 1;
    parameter string INPUT_DATA = "sar_adc_input_data.csv";
    parameter string OUTPUT_DATA = "sar_adc_output_data.csv";

    logic clk;
    logic reset;

    logic signed [BIT_DEPTH-1:0] input_data;
    logic signed [BIT_DEPTH+1:0] dac_data;

    logic comparator;
    logic dac_output;

    logic test;

    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) axis_if();

    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH+2)) to_fir_if();
    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH+2)) from_fir_if();

    sar_adc # (
        .DAC_OSR(DAC_OSR),
        .DAC_ORDER(DAC_ORDER)
    ) sar_adc_inst (
        .clk(clk),
        .reset(reset),

        .comparator(comparator),
        
        .code_output_if(axis_if),

        .dac_output(dac_output)
    );

    fir # (
        .TAPS(TAPS),
        .COEFF_W(COEFF_BIT_DEPTH),
        .FORM("DIRECT")
    ) fir_inst (
        .clk(clk),
        .rst(reset),
        .s_axis_if(to_fir_if),
        .m_axis_if(from_fir_if),
        .coeffs(coeffs)
    );

    AXIS_Master_BFM # (
        .data_width(BIT_DEPTH+2),
        .keep_enable(0),
        .user_width(0)
    ) to_fir_bfm;

    AXIS_Slave_BFM # (
        .data_width(BIT_DEPTH+2),
        .keep_enable(0),
        .user_width(0)
    ) from_fir_bfm;

    AXIS_Slave_BFM # (
        .data_width(BIT_DEPTH),
        .user_width(0),
        .keep_enable(0)
    ) axis_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    always_comb begin
        comparator = input_data > $signed(from_fir_if.tdata);
        dac_data = dac_output ? 18'h1ffff : 18'h20001;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;
            input_data = 0;

            test = 1'b0;

            to_fir_bfm = new(to_fir_if);
            from_fir_bfm = new(from_fir_if);
            axis_bfm = new(axis_if);

            to_fir_bfm.reset_task();
            from_fir_bfm.reset_task();
            axis_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        //`TEST_CASE("basic_test") begin
        //    for (int i = 0; i < BIT_DEPTH; i++) begin
        //        @ (posedge clk);
        //    end
        //    `CHECK_EQUAL(sar_adc_inst.conversion_buffer, 16'b0);
        //end

        `TEST_CASE("arb_input") begin
            static integer in_file = $fopen(INPUT_DATA, "r");
            static integer out_file = $fopen(OUTPUT_DATA, "w");
            static bit [BIT_DEPTH-1:0] dac_lpf_data;
            static bit signed [BIT_DEPTH-1:0] out_data;

            while ($fscanf(in_file, "%d", input_data) == 1) begin
                fork
                    begin
                        axis_bfm.simple_transfer(.clk(clk), .data(out_data));
                        $fwrite(out_file, "%d\n", out_data);
                        test = !test;
                    end
                    begin
                        for (int i = 0; i < DAC_OSR*BIT_DEPTH; i++) begin
                            fork
                                begin
                                    to_fir_bfm.transfer(.clk(clk), .data(dac_data));
                                end
                                begin
                                    from_fir_bfm.simple_transfer(.clk(clk), .data(dac_lpf_data));
                                end
                            join
                        end
                    end
                join
            end
            $fclose(in_file);
            $fclose(out_file);
        end
    end

    `WATCHDOG(2000ms);
endmodule

`default_nettype wire