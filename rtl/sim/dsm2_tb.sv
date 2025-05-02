/**
 * @file dsm2_tb.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief Second order Delta-Sigma modulator test bench.
 *        Accepts signed two's complement values from a csv.
 *        Outputs resulting (modulated) values into another csv.
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;

module dsm2_tb ();
    parameter int BIT_DEPTH = 16;
    parameter string INPUT_DATA = "dsm2_input_data.csv";
    parameter string OUTPUT_DATA = "dsm2_output_data.csv";

    logic clk;
    logic reset;

    logic out;

    AXIS_IF # (.TUSER_WIDTH(0), .TKEEP_ENABLE(0), .TDATA_WIDTH(BIT_DEPTH)) axis_if();

    dsm2 # () dsm2_inst (
        .clk(clk),
        .reset(reset),

        .axis_data_in_if(axis_if),

        .out(out)
    );

    AXIS_Master_BFM # (
        .data_width(BIT_DEPTH),
        .keep_enable(0),
        .user_width(0)
    ) axis_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;

            axis_bfm = new(axis_if);

            axis_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("simple") begin
            static integer out_file = $fopen(OUTPUT_DATA,"w");
            static integer in_file = $fopen(INPUT_DATA, "r");
            static bit signed [BIT_DEPTH-1:0] data;

            while ($fscanf(in_file, "%d", data) == 1) begin
                axis_bfm.transfer(.clk(clk), .data(data));
                $fwrite(out_file, "%d\n", out);
            end
            $fclose(out_file);
            $fclose(in_file);
        end
    end

    `WATCHDOG(10ms);
endmodule

`default_nettype wire