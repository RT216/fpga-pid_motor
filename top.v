//**********************************************************************
//  Project: TDPS
//  File: top.v
//  Description: top module
//  Author: Ruiqi Tang
//  Timestamp: 
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T       | 2024/04/03    | Initial version
// v1.1.0   | R.T       | 2024/04/05    | Update interface for 
//                                      | PID_i/p_proc, RPM_reader
// v1.2.0   | R.T       | 2024/05/04    | Update interface for
//                                      | PID_o/p_proc, UART_controller
// v1.2.1   | R.T       | 2024/05/05    | Fixed Typo, added clk_gen
// v1.3.0   | R.T.      | 2024/05/06    | Added stop signal
// v3.0.0   | R.T.      | 2024/05/14    | Update version number,
//                                        tested PID functionally
// v3.1.0   | R.T.      | 2024/05/17    | Refactoring the RPM_reader
// v3.3.0   | R.T.      | 2024/05/24    | Add brake signal
//**********************************************************************

module top (
    clk,
    rstn,

    enc0_a,
    enc0_b,
    enc1_a,
    enc1_b,
    enc2_a,
    enc2_b,
    enc3_a,
    enc3_b, 

    uart_rx,

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
    parameter DATA_WIDTH = 16;
    parameter PARAM_FRACTION_WIDTH = 8;

    parameter NUM_CHN = 4;
    localparam CHN_WIDTH = 3;
//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
// --- input ---
    input wire                      clk;
    input wire                      rstn;

    input wire                      uart_rx;

    input wire                      enc0_a;
    input wire                      enc0_b;
    input wire                      enc1_a;
    input wire                      enc1_b;
    input wire                      enc2_a;
    input wire                      enc2_b;
    input wire                      enc3_a;
    input wire                      enc3_b;

// --- output ---
    output wire                     motor_0_in_1;
    output wire                     motor_0_in_2;
    output wire                     motor_1_in_1;
    output wire                     motor_1_in_2;
    output wire                     motor_2_in_1;
    output wire                     motor_2_in_2;
    output wire                     motor_3_in_1;
    output wire                     motor_3_in_2;

//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    wire                        sample_clk;

    wire                        rpm0_ready;
    wire                        rpm1_ready;
    wire                        rpm2_ready;
    wire                        rpm3_ready;

    wire    [DATA_WIDTH-1:0]    rpm0_data_o;
    wire    [DATA_WIDTH-1:0]    rpm1_data_o;
    wire    [DATA_WIDTH-1:0]    rpm2_data_o;
    wire    [DATA_WIDTH-1:0]    rpm3_data_o;
    
    wire                        param_valid_i/*synthesis syn_keep=1*/;
    wire    [CHN_WIDTH-1:0]     param_chn_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_a1_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_a2_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_a3_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_b0_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_b1_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_b2_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_max_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    param_min_i/*synthesis syn_keep=1*/;

    wire                        tready_o/*synthesis syn_keep=1*/;

    wire                        data_valid_i/*synthesis syn_keep=1*/;
    wire    [CHN_WIDTH-1:0]     data_chn_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    data_fdb_i/*synthesis syn_keep=1*/;
    wire    [DATA_WIDTH-1:0]    data_ref_i/*synthesis syn_keep=1*/;

    wire                        u_valid_o;
    wire    [CHN_WIDTH-1:0]     u_chn_o;
    wire    [DATA_WIDTH-1:0]    u_data_o;

    wire                        tr_valid_o;
    wire    [CHN_WIDTH-1:0]     tr_chn_o;
    wire    [DATA_WIDTH-1:0]    tr_data_o;

    wire    [3:0]               stop;
    wire                        brake;

//**********************************************************************
// --- Main core
//**********************************************************************

//**********************************************************************
// --- Module: RPM_reader
// --- Description:
//      1. Quadruple the encoder's pulse
//      2. Calculate the RPM
//**********************************************************************
    RPM_reader RPM_reader_inst0(
        .clk            ( clk           ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc0_a        ),
        .enc_b          ( enc0_b        ),

        .rpm_valid_o    ( rpm0_ready    ),
        .rpm_data_o     ( rpm0_data_o   )
    );

    RPM_reader RPM_reader_inst1(
        .clk            ( clk           ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc1_a        ),
        .enc_b          ( enc1_b        ),

        .rpm_valid_o    ( rpm1_ready    ),
        .rpm_data_o     ( rpm1_data_o   )
    );

    RPM_reader RPM_reader_inst2(
        .clk            ( clk           ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc2_a        ),
        .enc_b          ( enc2_b        ),

        .rpm_valid_o    ( rpm2_ready    ),
        .rpm_data_o     ( rpm2_data_o   )
    );

    RPM_reader RPM_reader_inst3(
        .clk            ( clk           ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc3_a        ),
        .enc_b          ( enc3_b        ),

        .rpm_valid_o    ( rpm3_ready    ),
        .rpm_data_o     ( rpm3_data_o   )
    );

//**********************************************************************
// --- Module: PID_core
// --- Description:
//      3-pole/3-zero formula: 
//          U(n) = b0*E(n) + b1*E(n-1) + b2*E(n-2) + a1*U(n-1)+a2*U(n-2) + a3*U(n-3).
//**********************************************************************
    PID_Controller_3p3z_Top controller_3p3z_inst(
        .clk            ( clk           ),
        .rstn           ( rstn          ),

        .param_valid_i  ( param_valid_i ),
        .param_chn_i    ( param_chn_i   ),
        .param_a1_i     ( param_a1_i    ),
        .param_a2_i     ( param_a2_i    ),
        .param_a3_i     ( param_a3_i    ),
        .param_b0_i     ( param_b0_i    ),
        .param_b1_i     ( param_b1_i    ),
        .param_b2_i     ( param_b2_i    ),
        .param_max_i    ( param_max_i   ),
        .param_min_i    ( param_min_i   ),
                        
        .data_valid_i   ( data_valid_i  ),
        .data_chn_i     ( data_chn_i    ),
        .data_fdb_i     ( data_fdb_i    ),
        .data_ref_i     ( data_ref_i    ),
        .tready_o       ( tready_o      ),
                        
        .u_valid_o      ( u_valid_o     ),
        .u_chn_o        ( u_chn_o       ),
        .u_data_o       ( u_data_o      )
    );

//**********************************************************************
// --- Module: PID_input_processor
// --- Description:
//          1. parameter input 
//          2. input data from RPM reader
//**********************************************************************
    PID_Input_Processor   PID_Input_Processor_inst(
        .clk            ( clk           ),
        .rstn           ( rstn           ),

        .rpm0_ready     ( rpm0_ready     ),
        .rpm1_ready     ( rpm1_ready     ),
        .rpm2_ready     ( rpm2_ready     ),
        .rpm3_ready     ( rpm3_ready     ),

        .rpm0_data_o    ( rpm0_data_o    ),
        .rpm1_data_o    ( rpm1_data_o    ),
        .rpm2_data_o    ( rpm2_data_o    ),
        .rpm3_data_o    ( rpm3_data_o    ),

        .tr_valid_o     ( tr_valid_o     ),
        .tr_chn_o       ( tr_chn_o       ),
        .tr_data_o      ( tr_data_o      ),

        .param_valid_i  ( param_valid_i  ),
        .param_chn_i    ( param_chn_i    ),
        .param_a1_i     ( param_a1_i     ),
        .param_a2_i     ( param_a2_i     ),
        .param_a3_i     ( param_a3_i     ),
        .param_b0_i     ( param_b0_i     ),
        .param_b1_i     ( param_b1_i     ),
        .param_b2_i     ( param_b2_i     ),
        .param_max_i    ( param_max_i    ),
        .param_min_i    ( param_min_i    ),
                        
        .data_valid_i   ( data_valid_i   ),
        .data_chn_i     ( data_chn_i     ),
        .data_fdb_i     ( data_fdb_i     ),
        .data_ref_i     ( data_ref_i     ),
        .tready_o       ( tready_o       )
    );

//**********************************************************************
// --- Module: PID_output_processor
// --- Description:
//          convert the pid output to the pwm signal
//**********************************************************************
    PID_output_processor PID_output_processor_inst(
        .clk            ( clk           ),
        .rstn           ( rstn          ),

        .u_valid_o      ( u_valid_o     ),
        .u_chn_o        ( u_chn_o       ),
        .u_data_o       ( u_data_o      ),

        .stop           ( stop          ),
        .brake          ( brake         ),

        .motor_0_in_1   ( motor_0_in_1  ),
        .motor_0_in_2   ( motor_0_in_2  ),
        .motor_1_in_1   ( motor_1_in_1  ),
        .motor_1_in_2   ( motor_1_in_2  ),
        .motor_2_in_1   ( motor_2_in_1  ),
        .motor_2_in_2   ( motor_2_in_2  ),
        .motor_3_in_1   ( motor_3_in_1  ),
        .motor_3_in_2   ( motor_3_in_2  )
    );

//**********************************************************************
// --- Module: UART_controller
// --- Description:
//          1. receive data from uart_rx
//          2. send data to PID_input_processor
//**********************************************************************
    UART_controller UART_controller_inst(
        .clk            ( clk           ),
        .rstn           ( rstn          ),
        .uart_rx        ( uart_rx       ),

        .tr_valid_o     ( tr_valid_o    ),
        .tr_chn_o       ( tr_chn_o      ),
        .tr_data_o      ( tr_data_o     ),

        .stop           ( stop          ),
        .brake          ( brake         )
    );


endmodule