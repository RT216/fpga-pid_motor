//**********************************************************************
//  Project: TDPS
//  File: pid_output_processor.v
//  Description: convert the pid output to the pwm signal
//  Author: Ruiqi Tang
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/04/05    | Initial version
// v1.1.0   | R.T.      | 2024/04/06    | Update the pwm signal output
// v1.1.1   | R.T.      | 2024/04/22    | Removed pwm_clk
// v1.2.0   | R.T.      | 2024/05/06    | Added stop signal
// v3.0.0   | R.T.      | 2024/05/14    | Slower PWM frequency,
//                                        tested PID functionally
//**********************************************************************

module PID_output_processor(
    clk,
    rstn,

    u_valid_o,
    u_chn_o,
    u_data_o,

    stop,

    motor_0_in_1,
    motor_0_in_2,
    motor_1_in_1,
    motor_1_in_2,
    motor_2_in_1,
    motor_2_in_2,
    motor_3_in_1,
    motor_3_in_2
);

//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter   DATA_WIDTH = 16;

    parameter   NUM_CHN = 4;
    localparam  CHN_WIDTH = 3;

    parameter  integer RPM_MAX = 1024;

    parameter   CLK_FREQ = 27_000_000;  // Default = 27MHz
    parameter   PWM_FREQ = 27_000;     // Default = 10kHz

    localparam integer PWM_PERIOD = CLK_FREQ / PWM_FREQ - 1;    // Default = 999
    localparam integer COUNTER_WIDTH = $clog2(PWM_PERIOD + 1);  // Default = 10
    
    // count from 0 to PWM_PERIOD
        // counter threshold = (PWM_PERIOD + 1) * duty cycle%
        // pwm_out = counter < counter threshold
    // counter threshold for 20% and 80% duty cycle
    localparam integer PWM_DUTY_MIN = 0.2 * (PWM_PERIOD + 1);   // Default = 200
    localparam integer PWM_DUTY_MAX = 0.8 * (PWM_PERIOD + 1);   // Default = 800


//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input wire                      clk;
    input wire                      rstn;

    input wire                      u_valid_o;
    input wire  [CHN_WIDTH-1:0]     u_chn_o;
    input wire  [DATA_WIDTH-1:0]    u_data_o;

    input wire  [3:0]               stop;

    output reg                      motor_0_in_1;
    output reg                      motor_0_in_2;
    output reg                      motor_1_in_1;
    output reg                      motor_1_in_2;
    output reg                      motor_2_in_1;
    output reg                      motor_2_in_2;
    output reg                      motor_3_in_1;
    output reg                      motor_3_in_2;

//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    reg     [DATA_WIDTH-1:0]        u_data_ch0;
    reg     [DATA_WIDTH-1:0]        u_data_ch1;
    reg     [DATA_WIDTH-1:0]        u_data_ch2;
    reg     [DATA_WIDTH-1:0]        u_data_ch3;

    reg     [DATA_WIDTH-1:0]        u_data_ch0_abs;
    reg     [DATA_WIDTH-1:0]        u_data_ch1_abs;
    reg     [DATA_WIDTH-1:0]        u_data_ch2_abs;
    reg     [DATA_WIDTH-1:0]        u_data_ch3_abs;

    reg     [COUNTER_WIDTH-1:0]     counter_pwm;
    reg     [COUNTER_WIDTH-1:0]     pwm_thr_ch0;
    reg     [COUNTER_WIDTH-1:0]     pwm_thr_ch1;
    reg     [COUNTER_WIDTH-1:0]     pwm_thr_ch2;
    reg     [COUNTER_WIDTH-1:0]     pwm_thr_ch3;

//**********************************************************************
// --- Main core
//**********************************************************************
// --- handle the PID output data ---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            u_data_ch0 <= 0;
            u_data_ch1 <= 0;
            u_data_ch2 <= 0;
            u_data_ch3 <= 0;
        end
        else if(u_valid_o == 1'b1 && u_chn_o == 0) begin
            u_data_ch0 <= u_data_o;
        end
        else if(u_valid_o == 1'b1 && u_chn_o == 1) begin
            u_data_ch1 <= u_data_o;
        end
        else if(u_valid_o == 1'b1 && u_chn_o == 2) begin
            u_data_ch2 <= u_data_o;
        end
        else if(u_valid_o == 1'b1 && u_chn_o == 3) begin
            u_data_ch3 <= u_data_o;
        end
    end

// --- calculate abs
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            u_data_ch0_abs <= 0;
            u_data_ch1_abs <= 0;
            u_data_ch2_abs <= 0;
            u_data_ch3_abs <= 0;
        end
        else begin
            u_data_ch0_abs <= (u_data_ch0[DATA_WIDTH-1] == 1'b0)? u_data_ch0 : ~u_data_ch0 + 1;
            u_data_ch1_abs <= (u_data_ch1[DATA_WIDTH-1] == 1'b0)? u_data_ch1 : ~u_data_ch1 + 1;
            u_data_ch2_abs <= (u_data_ch2[DATA_WIDTH-1] == 1'b0)? u_data_ch2 : ~u_data_ch2 + 1;
            u_data_ch3_abs <= (u_data_ch3[DATA_WIDTH-1] == 1'b0)? u_data_ch3 : ~u_data_ch3 + 1;
        end
    end

// --- convert the PID output to the PWM signal---
// --- Description:
//      1. PID output range: -1024 ~ 1024
//      2. PWM duty cycle range: 20% ~ 80%
//      3. PWM frequency: 27kHz

    // ---counter_pwm
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            counter_pwm <= 0;
        end
        else if(counter_pwm == PWM_PERIOD) begin
            counter_pwm <= 0;
        end
        else begin
            counter_pwm <= counter_pwm + 1;
        end
    end

    // ---calculation for pwm_thr_chX
    //  using linear mapping:
    //      pwm_thr_chX = PWM_DUTY_MIN + (|u_data_chX| * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX)
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            pwm_thr_ch0 <= 0;
            pwm_thr_ch1 <= 0;
            pwm_thr_ch2 <= 0;
            pwm_thr_ch3 <= 0;
        end
        else begin
            if (stop[0])
                pwm_thr_ch0 <= 0;
            else
                pwm_thr_ch0 <= PWM_DUTY_MIN + ({{16'b0},u_data_ch0_abs} * (PWM_DUTY_MAX - PWM_DUTY_MIN)) / RPM_MAX;
            
            if (stop[1])
                pwm_thr_ch1 <= 0;
            else
                pwm_thr_ch1 <= PWM_DUTY_MIN + ({{16'b0},u_data_ch1_abs} * (PWM_DUTY_MAX - PWM_DUTY_MIN)) / RPM_MAX;

            if (stop[2])
                pwm_thr_ch2 <= 0;
            else
                pwm_thr_ch2 <= PWM_DUTY_MIN + ({{16'b0},u_data_ch2_abs} * (PWM_DUTY_MAX - PWM_DUTY_MIN)) / RPM_MAX;
            
            if (stop[3])
                pwm_thr_ch3 <= 0;
            else
                pwm_thr_ch3 <= PWM_DUTY_MIN + ({{16'b0},u_data_ch3_abs} * (PWM_DUTY_MAX - PWM_DUTY_MIN)) / RPM_MAX;
        end
    end
    
    // ---output the pwm signal
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            motor_0_in_1 <= 0;
            motor_0_in_2 <= 0;
            motor_1_in_1 <= 0;
            motor_1_in_2 <= 0;
            motor_2_in_1 <= 0;
            motor_2_in_2 <= 0;
            motor_3_in_1 <= 0;
            motor_3_in_2 <= 0;
        end
        else begin
            if (u_data_ch0[DATA_WIDTH-1] == 1'b0) begin
                motor_0_in_1 <= (counter_pwm < pwm_thr_ch0)? 1 : 0; // forward pwm
                motor_0_in_2 <= 0;                                  // fast decay
            end
            else begin
                motor_0_in_1 <= 0;                                  // fast decay
                motor_0_in_2 <= (counter_pwm < pwm_thr_ch0)? 1 : 0; // reverse pwm
            end

            if (u_data_ch1[DATA_WIDTH-1] == 1'b0) begin
                motor_1_in_1 <= (counter_pwm < pwm_thr_ch1)? 1 : 0; // forward pwm
                motor_1_in_2 <= 0;                                  // fast decay
            end
            else begin
                motor_1_in_1 <= 0;                                  // fast decay
                motor_1_in_2 <= (counter_pwm < pwm_thr_ch1)? 1 : 0; // reverse pwm
            end

            if (u_data_ch2[DATA_WIDTH-1] == 1'b0) begin
                motor_2_in_1 <= (counter_pwm < pwm_thr_ch2)? 1 : 0; // forward pwm
                motor_2_in_2 <= 0;                                  // fast decay
            end
            else begin
                motor_2_in_1 <= 0;                                  // fast decay
                motor_2_in_2 <= (counter_pwm < pwm_thr_ch2)? 1 : 0; // reverse pwm
            end

            if (u_data_ch3[DATA_WIDTH-1] == 1'b0) begin
                motor_3_in_1 <= (counter_pwm < pwm_thr_ch3)? 1 : 0; // forward pwm
                motor_3_in_2 <= 0;                                  // fast decay
            end
            else begin
                motor_3_in_1 <= 0;                                  // fast decay
                motor_3_in_2 <= (counter_pwm < pwm_thr_ch3)? 1 : 0; // reverse pwm
            end
        end
    end





endmodule