/**
 * @file dsm1.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief First order Delta-Sigma modulator.
 *        Accepts signed two's complement values as an input.
 *        Repeats the last sample if no new samples are available.
 */

`default_nettype none

module dsm1 # (
    // Prameters
) (
    input var logic clk,
    input var logic reset,

    AXIS_IF.Slave axis_data_in_if, // Signed two's complement

    output var logic out
);
    localparam BIT_DEPTH = axis_data_in_if.TDATA_WIDTH;
    localparam EXTENSION = 1;
    
    var logic signed [BIT_DEPTH+EXTENSION-1:0] pos_max = (2**(BIT_DEPTH-1)-1);
    var logic signed [BIT_DEPTH+EXTENSION-1:0] neg_max = -(2**(BIT_DEPTH-1)-1);

    var logic signed [BIT_DEPTH+EXTENSION-1:0] sign_ext_input;
    var logic signed [BIT_DEPTH+EXTENSION-1:0] accumulator;

    assign axis_data_in_if.tready = 1'b1;
    assign out = !accumulator[BIT_DEPTH+EXTENSION-1];

    // Sign extension and AXI-Stream logic
    always_ff @ (posedge clk) begin
        if (reset) begin            
            sign_ext_input <= '0;
        end else begin
            if (axis_data_in_if.tready && axis_data_in_if.tvalid) begin
                sign_ext_input <= {{EXTENSION{axis_data_in_if.tdata[BIT_DEPTH-1]}}, axis_data_in_if.tdata};
            end
        end
    end

    // Delta-sigma modulator
    always_ff @ (posedge clk) begin
        if (reset) begin
            accumulator <= '0;
        end else begin
            if (out) begin
                accumulator <= sign_ext_input + accumulator + neg_max;
            end else begin
                accumulator <= sign_ext_input + accumulator + pos_max;
            end
        end
    end
endmodule

`default_nettype wire