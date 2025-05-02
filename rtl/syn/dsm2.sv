/**
 * @file dsm2.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief Second order Delta-Sigma modulator.
 *        Accepts signed two's complement values as an input.
 *        Repeats the last sample if no new samples are available.
 */

`default_nettype none

module dsm2 # (
    // Parameters
) (
    input var logic clk,
    input var logic reset,

    AXIS_IF.Slave axis_data_in_if, // Signed two's complement

    output var logic out
);
    localparam BIT_DEPTH = axis_data_in_if.TDATA_WIDTH;

    localparam EXTENSION_1 = 3;
    localparam EXTENSION_2 = 8;

    var logic signed [BIT_DEPTH-1:0] dsm_input;
    var logic signed [BIT_DEPTH+EXTENSION_1-1:0] sign_ext_input;
    var logic signed [BIT_DEPTH+EXTENSION_1-1:0] accumulator_1;
    var logic signed [BIT_DEPTH+EXTENSION_2-1:0] accumulator_2;

    assign axis_data_in_if.tready = 1'b1;
    assign out = !accumulator_2[BIT_DEPTH+EXTENSION_2-1];

    always_comb begin
        dsm_input = axis_data_in_if.tdata;
    end

    // Sign extension and AXI-Stream logic
    always_ff @ (posedge clk) begin
        if (reset) begin            
            sign_ext_input <= '0;
        end else begin
            if (axis_data_in_if.tready && axis_data_in_if.tvalid) begin
                sign_ext_input <= {{EXTENSION_1{dsm_input[BIT_DEPTH-1]}}, dsm_input};
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (reset) begin
            accumulator_1 <= '0;
            accumulator_2 <= '0;
        end else begin
            if (out) begin
                accumulator_1 <= sign_ext_input + accumulator_1 - (2**(BIT_DEPTH)-1);
                accumulator_2 <= sign_ext_input + accumulator_1 + accumulator_2 - (2**(BIT_DEPTH+1)-2);
            end else begin
                accumulator_1 <= sign_ext_input + accumulator_1 + (2**(BIT_DEPTH)-1);
                accumulator_2 <= sign_ext_input + accumulator_1 + accumulator_2 + (2**(BIT_DEPTH+1)-2);
            end
        end
    end
endmodule

`default_nettype wire