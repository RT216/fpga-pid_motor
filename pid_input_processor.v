//**********************************************************************
//  Project: TDPS project
//  File: pid_ip_data_controller.v
//  Description: input signals generator for PID Controller
//  Author: Ruiqi Tang
//  Timestamp: 
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/04/02    | Initial version
// v1.1.0   | R.T.      | 2024/04/05    | Remove pid output, fix target
//                                      | rpm, and add some interface
//                                      | for the PID output processor
// v1.2.0   | R.T.      | 2024/04/08    | Add target rpm input
// v3.0.0   | R.T.      | 2024/05/14    | Slower PID frequency, tested 
//                                        PID functionally
// v3.0.1   | R.T.      | 2024/05/15    | Modified Parameters
// v3.1.0   | R.T.      | 2024/05/17    | Modified Parameters
// v3.2.0   | R.T.      | 2024/05/21    | Modified Parameters
//**********************************************************************
// `define AUTOMATIC_MEMORY

module PID_Input_Processor(
    clk, 
    rstn,

    rpm0_ready,
    rpm1_ready,
    rpm2_ready,
    rpm3_ready,

    rpm0_data_o,
    rpm1_data_o,
    rpm2_data_o,
    rpm3_data_o,

    tr_valid_o,
    tr_chn_o,
    tr_data_o,
    
    param_valid_i,
    param_chn_i,
    param_a1_i,
    param_a2_i,
    param_a3_i,
    param_b0_i,
    param_b1_i,
    param_b2_i,
    param_max_i,
    param_min_i,
    
    data_valid_i,
    data_chn_i,
    data_fdb_i,
    data_ref_i,
    tready_o
    
) /* synthesis syn_preserve=1*/;

//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter DATA_WIDTH = 16;

    parameter NUM_CHN = 4;
    localparam CHN_WIDTH = 3;
    // localparam CHN_WIDTH = (NUM_CHN>1)? $clog2(NUM_CHN):1; //bug?

    localparam NUM_CYCLE = 20;

    parameter RPM_MAX = 1023;

    parameter CLK_FREQ = 27_000_000;    // Default = 27MHz
    parameter PID_FREQ = 1500;          // Default = 1KHz
    localparam CNT_WIDTH = $clog2(CLK_FREQ/PID_FREQ) + 1; 

    parameter PARAM_A1 = 127;
    parameter PARAM_A2 = 64;
    parameter PARAM_A3 = 64;
    parameter PARAM_B0 = 26;
    parameter PARAM_B1 = 13;
    parameter PARAM_B2 = 13;

//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input wire                      clk;
    input wire                      rstn;

    input wire                      rpm0_ready;
    input wire                      rpm1_ready;
    input wire                      rpm2_ready;
    input wire                      rpm3_ready;

    input wire  [DATA_WIDTH-1:0]    rpm0_data_o;
    input wire  [DATA_WIDTH-1:0]    rpm1_data_o;
    input wire  [DATA_WIDTH-1:0]    rpm2_data_o;
    input wire  [DATA_WIDTH-1:0]    rpm3_data_o;

    input wire                      tr_valid_o;
    input wire  [CHN_WIDTH-1:0]     tr_chn_o;
    input wire  [DATA_WIDTH-1:0]    tr_data_o;

    output reg                      param_valid_i;
    output reg  [CHN_WIDTH-1:0]     param_chn_i;
    output reg  [DATA_WIDTH-1:0]    param_a1_i;
    output reg  [DATA_WIDTH-1:0]    param_a2_i;
    output reg  [DATA_WIDTH-1:0]    param_a3_i;
    output reg  [DATA_WIDTH-1:0]    param_b0_i;
    output reg  [DATA_WIDTH-1:0]    param_b1_i;
    output reg  [DATA_WIDTH-1:0]    param_b2_i;
    output reg  [DATA_WIDTH-1:0]    param_max_i;
    output reg  [DATA_WIDTH-1:0]    param_min_i;

    input wire                      tready_o;

    output reg                      data_valid_i;
    output reg  [CHN_WIDTH-1:0]     data_chn_i;
    output reg  [DATA_WIDTH-1:0]    data_fdb_i;
    output reg  [DATA_WIDTH-1:0]    data_ref_i;

//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    reg     [5:0]               cnt_cycle;
    reg                         param_valid;
    reg     [CHN_WIDTH-1:0]     param_chn;

    reg                         data_load;
    reg     [CHN_WIDTH:0]       data_cycle;

    reg     [DATA_WIDTH-1:0]    rpm_data_ch0;
    reg     [DATA_WIDTH-1:0]    rpm_data_ch1;
    reg     [DATA_WIDTH-1:0]    rpm_data_ch2;
    reg     [DATA_WIDTH-1:0]    rpm_data_ch3;

    reg     [DATA_WIDTH-1:0]    target_rpm_ch1;
    reg     [DATA_WIDTH-1:0]    target_rpm_ch2;
    reg     [DATA_WIDTH-1:0]    target_rpm_ch3;
    reg     [DATA_WIDTH-1:0]    target_rpm_ch0;

    reg     [CNT_WIDTH-1:0]     cnt_slow_down;
    reg                         ready_slow_down;

//**********************************************************************
// --- Main core
//**********************************************************************
// --- rpm sample & holding ---
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rpm_data_ch0 <= 0;
            rpm_data_ch1 <= 0;
            rpm_data_ch2 <= 0;
            rpm_data_ch3 <= 0;
        end
        else begin
            if (rpm0_ready == 1'b1)
                rpm_data_ch0 <= rpm0_data_o;
            else
                rpm_data_ch0 <= rpm_data_ch0;

            if (rpm1_ready == 1'b1)
                rpm_data_ch1 <= rpm1_data_o;
            else
                rpm_data_ch1 <= rpm_data_ch1;

            if (rpm2_ready == 1'b1)
                rpm_data_ch2 <= rpm2_data_o;
            else
                rpm_data_ch2 <= rpm_data_ch2;
                
            if (rpm3_ready == 1'b1)
                rpm_data_ch3 <= rpm3_data_o;
            else
                rpm_data_ch3 <= rpm_data_ch3;
        end
    end

// --- handle the target rpm data ---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            target_rpm_ch0 <= 0;
            target_rpm_ch1 <= 0;
            target_rpm_ch2 <= 0;
            target_rpm_ch3 <= 0;
        end
        else if(tr_valid_o == 1'b1 && tr_chn_o == 0) begin
            target_rpm_ch0 <= tr_data_o;
        end
        else if(tr_valid_o == 1'b1 && tr_chn_o == 1) begin
            target_rpm_ch1 <= tr_data_o;
        end
        else if(tr_valid_o == 1'b1 && tr_chn_o == 2) begin
            target_rpm_ch2 <= tr_data_o;
        end
        else if(tr_valid_o == 1'b1 && tr_chn_o == 3) begin
            target_rpm_ch3 <= tr_data_o;
        end
    end


// --- input parameter setting ---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_cycle <= 0;
        end
        else if(cnt_cycle == NUM_CYCLE-1) begin
            cnt_cycle <= cnt_cycle;
        end
        else begin
            cnt_cycle <= cnt_cycle + 1;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            param_valid <= 0;
            param_valid_i <= 0;
        end
        else begin
            param_valid <= ((cnt_cycle >= 5) && (cnt_cycle < NUM_CHN+5)) ? 1'b1:1'b0; //  5 <= cnt_cycle < 9
            param_valid_i <= param_valid;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            param_chn <= NUM_CHN-1;
        end
        else if(cnt_cycle == 5) begin
            param_chn <= 0;
        end
        else if(cnt_cycle < NUM_CHN+5 && cnt_cycle > 5) begin
            param_chn <= param_chn+1;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            param_chn_i <= NUM_CHN-1;
        end
        else begin
            param_chn_i <= param_chn;
        end    
    end

    always @(posedge clk) begin
        case(param_chn) 
            0:begin
                param_a1_i <= PARAM_A1;
                param_a2_i <= PARAM_A2;
                param_a3_i <= PARAM_A3;
                param_b0_i <= PARAM_B0;
                param_b1_i <= PARAM_B1;
                param_b2_i <= PARAM_B2;
                param_max_i <= RPM_MAX;
                param_min_i <= -RPM_MAX;
            end
            1: begin
                param_a1_i <= PARAM_A1;
                param_a2_i <= PARAM_A2;
                param_a3_i <= PARAM_A3;
                param_b0_i <= PARAM_B0;
                param_b1_i <= PARAM_B1;
                param_b2_i <= PARAM_B2;
                param_max_i <= RPM_MAX;
                param_min_i <= -RPM_MAX;
            end
            2: begin
                param_a1_i <= PARAM_A1;
                param_a2_i <= PARAM_A2;
                param_a3_i <= PARAM_A3;
                param_b0_i <= PARAM_B0;
                param_b1_i <= PARAM_B1;
                param_b2_i <= PARAM_B2;
                param_max_i <= RPM_MAX;
                param_min_i <= -RPM_MAX;
            end
            3: begin
                param_a1_i <= PARAM_A1;
                param_a2_i <= PARAM_A2;
                param_a3_i <= PARAM_A3;
                param_b0_i <= PARAM_B0;
                param_b1_i <= PARAM_B1;
                param_b2_i <= PARAM_B2;
                param_max_i <= RPM_MAX;
                param_min_i <= -RPM_MAX;
            end
            default: begin
                param_a1_i <= PARAM_A1;
                param_a2_i <= PARAM_A2;
                param_a3_i <= PARAM_A3;
                param_b0_i <= PARAM_B0;
                param_b1_i <= PARAM_B1;
                param_b2_i <= PARAM_B2;
                param_max_i <= RPM_MAX;
                param_min_i <= -RPM_MAX;
            end
        endcase
    end

// --- generate data input --- 
    // ---start data load after 10 clks---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_load <= 0;
        end
        else begin
            data_load <= (cnt_cycle >= 10)? 1'b1:1'b0;
        end
    end

    // ---slow down input frequency---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_slow_down <= 0;
            ready_slow_down <= 0;
        end
        else if(data_load & tready_o) begin
            if(cnt_slow_down == CLK_FREQ/PID_FREQ - 1) begin
                cnt_slow_down <= 0;
                ready_slow_down <= 1;
            end
            else begin
                cnt_slow_down <= cnt_slow_down + 1;
                ready_slow_down <= ready_slow_down;
            end
        end
        else begin
            cnt_slow_down <= 0;
            ready_slow_down <= 0;
        end
    end


    // ---data cycle (channel) counter---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_cycle <= NUM_CHN;
        end
        else if(data_load & tready_o & ready_slow_down) begin
            if(data_cycle == NUM_CHN) 
                data_cycle <= 0;
            else 
                data_cycle <= data_cycle + 1;
        end
    end

    // ---feed data input---
    always @(*) begin
        if(data_cycle == NUM_CHN) begin
            data_valid_i <= 1'b0;
            data_chn_i <= NUM_CHN-1;
            data_fdb_i <= 0;
            data_ref_i <= 0;
        end
        else if(data_cycle == 0) begin
            data_valid_i <= 1'b1;
            data_chn_i <= 0;
            data_fdb_i <= rpm_data_ch0;
            data_ref_i <= target_rpm_ch0;
        end
        else if(data_cycle == 1)  begin
            data_valid_i <= 1'b1;
            data_chn_i <= 1;
            data_fdb_i <= rpm_data_ch1;
            data_ref_i <= target_rpm_ch1;
        end
        else if(data_cycle == 2)  begin
            data_valid_i <= 1'b1;
            data_chn_i <= 2;
            data_fdb_i <= rpm_data_ch2;
            data_ref_i <= target_rpm_ch2;
        end
        else begin
            data_valid_i <= 1'b1;
            data_chn_i <= data_cycle;
            data_fdb_i <= rpm_data_ch3;
            data_ref_i <= target_rpm_ch3;
        end
    end

endmodule