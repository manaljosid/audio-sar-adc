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
import fir_tb_coeffs::*;

module fir_tb ();
    parameter int BIT_DEPTH = 16;
    parameter string INPUT_DATA = "fir_tb_input_data.csv";
    parameter string OUTPUT_DATA = "fir_tb_output_data.csv";

    logic clk;
    logic reset;

    logic signed [BIT_DEPTH-1:0] input_data;
    logic signed [BIT_DEPTH-1:0] output_data;

    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) to_fir_if();
    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) from_fir_if();

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
        .data_width(BIT_DEPTH),
        .keep_enable(0),
        .user_width(0)
    ) to_fir_bfm;

    AXIS_Slave_BFM # (
        .data_width(BIT_DEPTH),
        .keep_enable(0),
        .user_width(0)
    ) from_fir_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;
            input_data = 0;

            to_fir_bfm = new(to_fir_if);
            from_fir_bfm = new(from_fir_if);

            to_fir_bfm.reset_task();
            from_fir_bfm.reset_task();

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

            while ($fscanf(in_file, "%d", input_data) == 1) begin
                fork
                    begin
                        to_fir_bfm.transfer(.clk(clk), .data(input_data));
                    end
                    begin
                        from_fir_bfm.simple_transfer(.clk(clk), .data(output_data));
                        $fwrite(out_file, "%d\n", output_data);
                    end
                join
            end
            $fclose(in_file);
            $fclose(out_file);
        end
    end

    `WATCHDOG(1000ms);
endmodule

`default_nettype wire