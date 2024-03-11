//**********************************************************************
// 	Project: TDPS
//	File: top.v
// 	Description: top module
//	Author: 
//  Timestamp: 
//----------------------------------------------------------------------
// Code Revision History:
// Ver:		| Author 	| Mod. Date		| Changes Made:
// v1.0.0	| xxx		| xx/xx/20xx	| Initial version
//**********************************************************************

module top (
	clk,
	rstn,
	
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
	input wire 						clk;
	input wire 					 	rstn;
	
// --- output ---	
	output wire					 	u_valid_o;
	output wire [CHN_WIDTH-1:0]		u_chn_o;
	output wire [DATA_WIDTH-1:0]	u_data_o;
	
//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
	wire 					 	param_valid_i/*synthesis syn_keep=1*/;
	wire 	[CHN_WIDTH-1:0] 	param_chn_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_a1_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_a2_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_a3_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_b0_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_b1_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_b2_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_max_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	param_min_i/*synthesis syn_keep=1*/;

	wire						tready_o/*synthesis syn_keep=1*/;
	
	wire 					 	data_valid_i/*synthesis syn_keep=1*/;
	wire 	[CHN_WIDTH-1:0] 	data_chn_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	data_fdb_i/*synthesis syn_keep=1*/;
	wire 	[DATA_WIDTH-1:0] 	data_ref_i/*synthesis syn_keep=1*/;


//**********************************************************************
// --- Module: Controller_3p3z
// --- Description:	
//		3-pole/3-zero formula: 
//				U(n) = b0*E(n) + b1*E(n-1) + b2*E(n-2) + a1*U(n-1)+a2*U(n-2) + a3*U(n-3).
//**********************************************************************
	PID_Controller_3p3z_Top controller_3p3z_inst(
		.clk			( clk 			),
		.rstn			( rstn			),
		
		.param_valid_i	( param_valid_i	),
		.param_chn_i	( param_chn_i	),
		.param_a1_i		( param_a1_i	),
		.param_a2_i		( param_a2_i	),
		.param_a3_i		( param_a3_i	),				
		.param_b0_i		( param_b0_i	),
		.param_b1_i		( param_b1_i	),
		.param_b2_i		( param_b2_i	),
		.param_max_i	( param_max_i	),
		.param_min_i	( param_min_i	),
						  
		.data_valid_i	( data_valid_i	),
		.data_chn_i		( data_chn_i	),
		.data_fdb_i		( data_fdb_i	),
		.data_ref_i		( data_ref_i	),
		.tready_o		( tready_o		),
						  
		.u_valid_o		( u_valid_o		),
		.u_chn_o		( u_chn_o		),
		.u_data_o		( u_data_o		)
	);
	
//**********************************************************************
// --- Module: input_gen 
// --- Description:	
// 			1. parameter input simulation
// 			2. input data generator (with 3 channels) simulation
//**********************************************************************
	PID_Input_Processor   PID_Input_Processor_inst(
		.clk			( clk 			),
		.rstn			( rstn			),
		
		.param_valid_i	( param_valid_i	),
		.param_chn_i	( param_chn_i	),
		.param_a1_i		( param_a1_i	),
		.param_a2_i		( param_a2_i	),
		.param_a3_i		( param_a3_i	),				
		.param_b0_i		( param_b0_i	),
		.param_b1_i		( param_b1_i	),
		.param_b2_i		( param_b2_i	),
		.param_max_i	( param_max_i	),
		.param_min_i	( param_min_i	),
						  
		.data_valid_i	( data_valid_i	),
		.data_chn_i		( data_chn_i	),
		.data_fdb_i		( data_fdb_i	),
		.data_ref_i		( data_ref_i	),
		.tready_o		( tready_o		),
		
		.u_valid_o		( u_valid_o		),
		.u_chn_o		( u_chn_o		),
		.u_data_o		( u_data_o		)
						  
	);
	defparam input_gen_inst.DATA_WIDTH = DATA_WIDTH;

endmodule