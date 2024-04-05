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
//**********************************************************************

module PID_output_processor(
    clk,
    rstn,
    clk_pwm,
    
    u_valid_o,
    u_chn_o,
    u_data_o,

    motor_0_stop,
    motor_1_stop,
    motor_2_stop,
    motor_3_stop,

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

    parameter   RPM_MAX = 1500;

    parameter   CLK_FREQ = 27_000_000;  // Default = 27MHz
    parameter   PWM_FREQ = 100_000;     // Default = 100kHz

    localparam integer PWM_PERIOD = CLK_FREQ / PWM_FREQ - 1;    // Default = 269
    localparam integer COUNTER_WIDTH = $clog2(PWM_PERIOD + 1);  // Default = 9
    
    // count from 0 to PWM_PERIOD
        // counter threshold = (PWM_PERIOD + 1) * duty cycle%
        // pwm_out = counter < counter threshold
    // counter threshold for 20% and 80% duty cycle
    localparam integer PWM_DUTY_MIN = 0.2 * (PWM_PERIOD + 1);   // Default = 54
    localparam integer PWM_DUTY_MAX = 0.8 * (PWM_PERIOD + 1);   // Default = 215


//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input wire                      clk;
    input wire                      rstn;
    input wire                      clk_pwm;

    input wire                      u_valid_o;
    input wire  [CHN_WIDTH-1:0]     u_chn_o;
    input wire  [DATA_WIDTH-1:0]    u_data_o;

    input wire                      motor_0_stop;
    input wire                      motor_1_stop;
    input wire                      motor_2_stop;
    input wire                      motor_3_stop;

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

// --- convert the PID output to the PWM signal---
// --- Description:
//      1. PID output range: -1500 ~ 1500
//      2. PWM duty cycle range: 20% ~ 80%
//      3. PWM frequency: 1kHz

    // ---counter_pwm
    always @(posedge clk_pwm or negedge rstn) begin
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
    always @(posedge clk_pwm or negedge rstn) begin
        if(!rstn) begin
            pwm_thr_ch0 <= 0;
            pwm_thr_ch1 <= 0;
            pwm_thr_ch2 <= 0;
            pwm_thr_ch3 <= 0;
        end
        else begin
            if (u_data_ch0 > 0)
                pwm_thr_ch0 <= PWM_DUTY_MIN + (u_data_ch0 * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            else
                pwm_thr_ch0 <= PWM_DUTY_MIN + ((-u_data_ch0) * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            
            if (u_data_ch1 > 0)
                pwm_thr_ch1 <= PWM_DUTY_MIN + (u_data_ch1 * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            else
                pwm_thr_ch1 <= PWM_DUTY_MIN + ((-u_data_ch1) * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            
            if (u_data_ch2 > 0)
                pwm_thr_ch2 <= PWM_DUTY_MIN + (u_data_ch2 * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            else
                pwm_thr_ch2 <= PWM_DUTY_MIN + ((-u_data_ch2) * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            
            if (u_data_ch3 > 0)
                pwm_thr_ch3 <= PWM_DUTY_MIN + (u_data_ch3 * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
            else
                pwm_thr_ch3 <= PWM_DUTY_MIN + ((-u_data_ch3) * (PWM_DUTY_MAX - PWM_DUTY_MIN) / RPM_MAX);
        end
    end
    






endmodule