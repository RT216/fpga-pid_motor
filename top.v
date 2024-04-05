//**********************************************************************
//  Project: TDPS
//  File: top.v
//  Description: top module
//  Author: 
//  Timestamp: 
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T       | 2024/04/03    | Initial version
// v1.1.0   | R.T       | 2024/04/05    | Update interface for 
//                                      | PID_i/p_proc, RPM_reader
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

    u_valid_o,
    u_chn_o,
    u_data_o
);


//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter DATA_WIDTH = 16;
    parameter PARAM_FRACTION_WIDTH = 8;

    parameter NUM_CHN = 4;
    localparam CHN_WIDTH = (NUM_CHN>1)? $clog2(NUM_CHN):1;
//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
// --- input ---
    input wire                      clk;
    input wire                      rstn;

    input wire                      enc0_a;
    input wire                      enc0_b;
    input wire                      enc1_a;
    input wire                      enc1_b;
    input wire                      enc2_a;
    input wire                      enc2_b;
    input wire                      enc3_a;
    input wire                      enc3_b;

// --- output ---
    output wire                     u_valid_o;
    output wire [CHN_WIDTH-1:0]     u_chn_o;
    output wire [DATA_WIDTH-1:0]    u_data_o;

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


//**********************************************************************
// --- Module: RPM_Reader
// --- Description:
//      1. Quadruple the encoder's pulse
//      2. Calculate the RPM
//**********************************************************************
    RPM_Reader RPM_Reader_inst0(
        .clk            ( clk           ),
        .sample_clk     ( sample_clk    ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc0_a        ),
        .enc_b          ( enc0_b        ),

        .rpm_valid_o    ( rpm0_ready    ),
        .rpm_data_o     ( rpm0_data_o   )
    );

    RPM_Reader RPM_Reader_inst1(
        .clk            ( clk           ),
        .sample_clk     ( sample_clk    ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc1_a        ),
        .enc_b          ( enc1_b        ),

        .rpm_valid_o    ( rpm1_ready    ),
        .rpm_data_o     ( rpm1_data_o   )
    );

    RPM_Reader RPM_Reader_inst2(
        .clk            ( clk           ),
        .sample_clk     ( sample_clk    ),
        .rstn           ( rstn          ),
        
        .enc_a          ( enc2_a        ),
        .enc_b          ( enc2_b        ),

        .rpm_valid_o    ( rpm2_ready    ),
        .rpm_data_o     ( rpm2_data_o   )
    );

    RPM_Reader RPM_Reader_inst3(
        .clk            ( clk           ),
        .sample_clk     ( sample_clk    ),
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

        .target_rpm_ch0 ( target_rpm_ch0 ),
        .target_rpm_ch1 ( target_rpm_ch1 ),
        .target_rpm_ch2 ( target_rpm_ch2 ),
        .target_rpm_ch3 ( target_rpm_ch3 ),

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
    defparam input_gen_inst.DATA_WIDTH = DATA_WIDTH;

endmodule