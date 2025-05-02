/**
 * @file fir.sv
 * 
 * @author scapekambing (modified by Mani Magnusson)
 *
 * @date   2025
 * 
 * @brief Fixed-point FIR filter with AXI-Stream interfaces
 */

`timescale 1ns / 1ps
`default_nettype none

module fir #(
    parameter int TAPS = 15,
    parameter int COEFF_W = 16,
    parameter FORM = "DIRECT" // "DIRECT", "PIPELINED_DIRECT", "PIPELINED_TRANSPOSED", "TRANSPOSED"
) (
    input var logic clk,
    input var logic rst, 
    AXIS_IF.Slave s_axis_if,  
    AXIS_IF.Master m_axis_if,
    input var logic signed [COEFF_W-1:0] coeffs [TAPS]
);

    localparam DATA_W = s_axis_if.TDATA_WIDTH;
    localparam MULT_W = DATA_W+COEFF_W;
    localparam ACCM_W = DATA_W+COEFF_W+$clog2(TAPS);

    var logic signed [DATA_W-1:0] fir_data_in;
    var logic signed [DATA_W-1:0] fir_data_buff [TAPS];
    var logic signed [DATA_W-1:0] fir_data_pipe [TAPS];
    var logic signed [MULT_W-1:0] multiplied_fir_data [TAPS];
    var logic signed [ACCM_W-1:0] accumulator_path [TAPS];
    var logic signed [ACCM_W-1:0] fir_data_out;
    var logic signed [ACCM_W-1:0] fir_data_out_next;
    var logic [MULT_W-1:0] fir_data_out_tozero;

    always_comb begin
        fir_data_out_tozero = '0;
        if (m_axis_if.tready && m_axis_if.tvalid) begin
            fir_data_out_tozero = fir_data_out[MULT_W-1:0] + { {(m_axis_if.TDATA_WIDTH){1'b0}}, fir_data_out[MULT_W-1], 
                                    {(MULT_W-m_axis_if.TDATA_WIDTH-1){!fir_data_out[MULT_W-1]}}};
        end
    end

    generate 
    if(FORM=="DIRECT") begin
        always_comb begin
            fir_data_out_next = '0;
            if (m_axis_if.tready && m_axis_if.tvalid) begin
                for (int i = 0; i < TAPS; i++) begin
                    fir_data_out_next = fir_data_out_next + fir_data_buff[i] * coeffs[i];
                end
            end
        end
    end
    endgenerate

    always_comb begin
        m_axis_if.tvalid = s_axis_if.tvalid;
        s_axis_if.tready = m_axis_if.tready;
    end

    // FIR logic 
    generate
    always_ff @(posedge clk) begin
        if (rst) begin
            fir_data_in <= '0;  
            for (int i = 0; i < TAPS; i++) begin
                fir_data_buff[i] <= '0;
                multiplied_fir_data[i] <= '0;
                accumulator_path[i] <= '0;
                fir_data_pipe[i] <= '0;
            end
            fir_data_out <= '0;
            m_axis_if.tdata <= '0;
        end else begin
            if (m_axis_if.tready && m_axis_if.tvalid) begin
                fir_data_in <= s_axis_if.tdata;

                case(FORM)
                    "PIPELINED_DIRECT": begin
                        fir_data_buff[0] <= fir_data_in;
                        fir_data_pipe[0] <= fir_data_buff[0];
                        accumulator_path[0] <= fir_data_in * coeffs[0];
                        for (int i = 1; i < TAPS; i++) begin
                            fir_data_buff[i] <= fir_data_pipe[i-1];
                            fir_data_pipe[i] <= fir_data_buff[i];
                            accumulator_path[i] <= fir_data_pipe[i-1] * coeffs[i] + accumulator_path[i-1];
                        end
                        fir_data_out <= accumulator_path[TAPS-1];
                    end
                    "PIPELINED_TRANSPOSED": begin
                        multiplied_fir_data[0] <= fir_data_in * coeffs[TAPS-1];
                        accumulator_path[0] <= multiplied_fir_data[0];
                        for (int i = 1; i < TAPS; i++) begin
                            multiplied_fir_data[i] <= fir_data_in * coeffs[TAPS-1-i];
                            accumulator_path[i] <= multiplied_fir_data[i] + accumulator_path[i-1];
                        end
                        fir_data_out <= accumulator_path[TAPS-1];
                    end
                    "TRANSPOSED": begin
                        accumulator_path[0] <= fir_data_in + coeffs[TAPS-1];
                        for (int i = 1; i < TAPS; i++) begin
                            accumulator_path[i] <= fir_data_in * coeffs[TAPS-1-i] + accumulator_path[i-1];
                        end
                        fir_data_out = accumulator_path[TAPS-1];
                    end
                    default: begin // "DIRECT"
                        fir_data_buff[0] <= fir_data_in;
                        for (int i = 1; i < TAPS; i++) begin
                            fir_data_buff[i] <= fir_data_buff[i-1];
                        end
                        fir_data_out <= fir_data_out_next;
                    end
                endcase
                m_axis_if.tdata <= fir_data_out_tozero[(MULT_W-1) -: m_axis_if.TDATA_WIDTH];
            end else begin
                //fir_data_in <= '0;
                //m_axis_if.tdata <= m_axis_if.tdata;
            end
        end
    end
    endgenerate
endmodule

`default_nettype wire


