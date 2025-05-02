/**
 * @file sar_adc_tb.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief SAR ADC state machine testbench
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;

module sar_fsm_tb ();
    parameter int BIT_DEPTH = 16;
    logic signed [BIT_DEPTH-1:0] input_signal = 16'sh1234;//{BIT_DEPTH{1'b1}};
    parameter int DAC_OSR = 4;

    logic clk;
    logic reset;

    logic comparator;

    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) adc_code_if();
    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) reference_dac_if();

    sar_fsm # (
        .BIT_DEPTH(BIT_DEPTH)
    ) sar_fsm_inst (
        .clk(clk),
        .reset(reset),

        .adc_code_output_if(adc_code_if),
        .reference_dac_output_if(reference_dac_if),

        .comparator(comparator)
    );

    AXIS_Slave_BFM # (
        .data_width(BIT_DEPTH),
        .user_width(0),
        .keep_enable(0)
    ) adc_code_bfm;

    AXIS_Slave_BFM # (
        .data_width(BIT_DEPTH),
        .user_width(0),
        .keep_enable(0)
    ) reference_dac_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    always_comb begin
        comparator = input_signal >= $signed(reference_dac_if.tdata);
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;

            adc_code_bfm = new(adc_code_if);
            adc_code_bfm.reset_task();

            reference_dac_bfm = new(reference_dac_if);
            reference_dac_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("basic_test") begin
            static bit signed [BIT_DEPTH-1:0] dac_data;
            static bit signed [BIT_DEPTH-1:0] code_data;
            // Run a few times to make sure we always get the correct output
            for (int k = 0; k < 4; k++) begin
                for (int i = 0; i < BIT_DEPTH; i++) begin
                    reference_dac_bfm.simple_transfer(.clk(clk), .data(dac_data));
                end
                adc_code_bfm.simple_transfer(.clk(clk), .data(code_data));
                //@ (posedge clk);
                `CHECK_EQUAL(code_data, input_signal);
                input_signal = ~(input_signal + 11);
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire