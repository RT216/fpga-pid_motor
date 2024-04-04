//**********************************************************************
//  Project: TDPS
//  File: rpm_reader.v
//  Description: convert the input pulse to the rpm data
//  Author: Ruiqi Tang
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/03/09    | Initial version
// v1.0.1   | R.T.      | 2024/04/02    | Fixed the data width problem
//**********************************************************************

module RPM_reader(clk,
                  rstn,
                  enc_a,
                  enc_b,
                  rpm_valid_o,
                  rpm_data_o);
    
//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter DATA_WIDTH = 16;
    localparam CLK_FREQ  = 10_000_000;
    
//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input wire                      clk;
    input wire                      rstn;
    
    input wire                      enc_a;
    input wire                      enc_b;
    
    output reg                      rpm_valid_o;
    output reg  [DATA_WIDTH-1:0]    rpm_data_o;
    
//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    
    reg       [3:0]                 counter_m0;     // count for the encoder's pulse
    reg       [15:0]                counter_m1;     // count for a high freq (100k)
    
    reg                             counter_clear;
    
    reg                             current_enc_a;
    reg                             current_enc_b;
    
    reg                             quadrupled_pulse;
    
    
//**********************************************************************
// --- Main Core
//**********************************************************************
// --- Encoder frequency quadrupling
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            current_enc_a    <= 0;
            current_enc_b    <= 0;
        end
        else begin
            current_enc_a <= enc_a;
            current_enc_b <= enc_b;
        end
    end
    
    always @(*) begin
        if ((current_enc_a ^ enc_a) || (current_enc_b ^ enc_b)) begin
            quadrupled_pulse = 1'b1;
            end
        else begin
            quadrupled_pulse = 1'b0;
        end
    end
    
// --- Counter (M0) for encoder's pulse
    always @(posedge quadrupled_pulse or negedge rstn or posedge counter_clear) begin
        if (!rstn || counter_clear) begin
            counter_m0 <= 0;
        end
        else begin
            counter_m0 <= counter_m0 + 1;
        end
    end
    
// --- Counter (M1) for a high freq (clk/10k)
    always @(posedge clk or negedge rstn or posedge counter_clear) begin
        if (!rstn || counter_clear) begin
            counter_m1 <= 0;
        end
        else begin
            counter_m1 <= counter_m1 + 1;
        end
    end
    
// --- RPM calculation
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rpm_valid_o   <= 0;
            rpm_data_o    <= 0;
            counter_clear <= 0;
        end
        else begin
            if (counter_m0 > 3 || counter_m1 > 8192) begin
                counter_clear <= 1'b1;
                rpm_valid_o   <= 1'b1;
                rpm_data_o    <=  {28'b0, counter_m0} * 32'd367647 / {16'b0, counter_m1};
            end
            else begin
                counter_clear <= 0;
                rpm_valid_o   <= 0;
            end
        end
    end

    
endmodule
