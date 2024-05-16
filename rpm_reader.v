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
// v1.1.0   | R.T.      | 2024/04/05    | Add support for reverse rotation
// v3.0.0   | R.T.      | 2024/05/14    | Modified the RPM counter limit,
//                                        tested PID functionally
// v3.0.1   | R.T.      | 2024/05/15    | Modified Parameters
// v3.1.0   | R.T.      | 2024/05/17    | Refactoring the RPM_reader
//**********************************************************************

module RPM_reader(
    clk,
    rstn,

    enc_a,
    enc_b,
    
    rpm_valid_o,
    rpm_data_o
);
    
//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter DATA_WIDTH = 16;
    parameter CLK_FREQ  = 27_000_000;
    
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
    reg       [31:0]                counter_a;
    reg       [31:0]                counter_a_reg;
    reg       [31:0]                counter_b;
    
    reg                             current_enc_a;
    reg                             current_enc_b;
    
//**********************************************************************
// --- Main Core
//**********************************************************************

// --- Encoder sampling ---
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
    

// --- Counter a & b for the period between two encoder's negedge ---
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            counter_a <= 0;
            counter_b <= 0;

            counter_a_reg <= 0;

            rpm_valid_o <= 0;
            rpm_data_o <= 0;
        end
        else begin
            if (!enc_a && current_enc_a) begin
                counter_a <= 0;
                counter_a_reg <= counter_a;
                rpm_valid_o <= 0;
            end
            else if (!enc_b && current_enc_b) begin
                counter_b <= 0;

                if (counter_a > (60*CLK_FREQ/408) || counter_b > (60*CLK_FREQ/408)) begin
                    rpm_valid_o <= 0;
                end else begin
                    rpm_valid_o <= 1;
                    if (counter_a < (counter_b >> 1)) begin  // forward rotation
                        // rpm_data_o <= ((120/408) / (counter_a_reg +  counter_b)) * CLK_FREQ;
                        rpm_data_o <= (7941176) / (counter_a_reg +  counter_b);
                    end else begin
                        // rpm_data_o <= -((120/408) / (counter_a_reg +  counter_b)) * CLK_FREQ;
                        rpm_data_o <= -((7941176) / (counter_a_reg +  counter_b));
                    end
                end

            end
            else begin
                counter_a <= counter_a + 1;
                counter_b <= counter_b + 1;
                rpm_valid_o <= 0;
            end
        end
    end

endmodule
