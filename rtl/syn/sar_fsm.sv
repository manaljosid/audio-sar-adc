/**
 * @file sar_adc.sv
 * 
 * @author Mani Magnusson
 * @date   2025
 *
 * @brief SAR ADC state machine
 */

`default_nettype none

module sar_fsm # (
    parameter int BIT_DEPTH = 16,
    parameter int DAC_OSR = 512
) (
    input var logic clk,
    input var logic reset,

    AXIS_IF.Master adc_code_output_if,
    AXIS_IF.Master reference_dac_output_if,

    input var logic comparator
);
    initial begin
        assert (BIT_DEPTH > 0)
        else $error("Assertion in %m failed, BIT_DEPTH must be larger than zero");
    end
    
    initial begin
        assert (DAC_OSR > 0)
        else $error("Assertion in %m failed, DAC_OSR must be larger than zero");
    end

    typedef enum {
        CONV_STATE_MSB,
        CONV_STATE_CONV,
        CONV_STATE_LSB
    } conv_state_t;

    conv_state_t conv_state;

    typedef enum {
        CODE_AXIS_STATE_IDLE,
        CODE_AXIS_STATE_TRANSFER
    } code_axis_state_t;
    
    code_axis_state_t code_axis_state;

    var logic [$clog2(BIT_DEPTH)-1:0] bit_idx;
    var logic signed [BIT_DEPTH-1:0] conv_reg;
    var logic eoc;
    var logic [$clog2(DAC_OSR)-1:0] osr_counter;

    assign reference_dac_output_if.tvalid = 1'b1;
    assign reference_dac_output_if.tdata = conv_reg;

    always_ff @ (posedge clk) begin
        if (reset) begin
            bit_idx <= BIT_DEPTH-1;

            conv_reg <= '0;

            conv_state <= CONV_STATE_MSB;

            osr_counter <= '0;
        end else begin
            // The reference DAC controls the data flow
            if (osr_counter == DAC_OSR-1) begin
                osr_counter <= '0;

                case (conv_state)
                    CONV_STATE_MSB : begin
                        conv_reg[bit_idx] <= !comparator;
                        conv_reg[bit_idx - 1] <= 1'b1;

                        bit_idx <= bit_idx - 1;
                        conv_state <= CONV_STATE_CONV;
                    end
                    CONV_STATE_CONV : begin
                        conv_reg[bit_idx] <= comparator;
                        conv_reg[bit_idx - 1] <= 1'b1;
                        
                        bit_idx <= bit_idx - 1;
                        if (bit_idx == 1) begin
                            conv_state <= CONV_STATE_LSB;
                        end
                    end
                    CONV_STATE_LSB : begin
                        conv_reg <= '0;
                        
                        bit_idx <= BIT_DEPTH-1;
                        conv_state <= CONV_STATE_MSB;
                    end
                endcase
            end else begin
                osr_counter <= osr_counter + 1;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (reset) begin
            adc_code_output_if.tdata <= '0;
            adc_code_output_if.tvalid <= 1'b0;
            eoc <= 1'b0;
            code_axis_state <= CODE_AXIS_STATE_IDLE;
        end else begin
            case (code_axis_state)
                CODE_AXIS_STATE_IDLE : begin
                    if (conv_state == CONV_STATE_LSB && !eoc) begin
                        adc_code_output_if.tdata <= {conv_reg[BIT_DEPTH-1:1], comparator};
                        adc_code_output_if.tvalid <= 1'b1;
                        eoc <= 1'b1;
                        code_axis_state <= CODE_AXIS_STATE_TRANSFER;
                    end
                end
                CODE_AXIS_STATE_TRANSFER : begin
                    if (adc_code_output_if.tready && adc_code_output_if.tvalid) begin
                        adc_code_output_if.tvalid <= 1'b0;
                        eoc <= 1'b0;
                        code_axis_state <= CODE_AXIS_STATE_IDLE;
                    end
                end
            endcase
            
        end
    end

endmodule

`default_nettype wire