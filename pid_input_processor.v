
//**********************************************************************
// 	Project: TDPS project
//	File: pid_ip_data_controller.v
// 	Description: input signals generator for PID Controller
//	Author: XXX
//  Timestamp: 
//----------------------------------------------------------------------
// Code Revision History:
// Ver:		| Author 	| Mod. Date		| Changes Made:
// v1.0.0	| XXX		| XX/XX/20XX	| Initial version
//**********************************************************************
// `define AUTOMATIC_MEMORY

module PID_Input_Processor(
		clk, 
		rstn,
		
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
		tready_o,
		
		u_valid_o,
		u_chn_o,
		u_data_o
		
) /* synthesis syn_preserve=1*/;

//**********************************************************************
// --- Parameter
//**********************************************************************
	parameter DATA_WIDTH = 16;
	
	parameter NUM_CHN = 4;
	localparam CHN_WIDTH = (NUM_CHN>1)? $clog2(NUM_CHN):1;
	
	localparam NUM_CYCLE = 20;

//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
	input wire 						clk;
	input wire 					 	rstn;

	output reg 					 	param_valid_i;
	output reg 	[CHN_WIDTH-1:0] 	param_chn_i;
	output reg 	[DATA_WIDTH-1:0] 	param_a1_i;
	output reg 	[DATA_WIDTH-1:0] 	param_a2_i;
	output reg 	[DATA_WIDTH-1:0] 	param_a3_i;
	output reg 	[DATA_WIDTH-1:0] 	param_b0_i;
	output reg 	[DATA_WIDTH-1:0] 	param_b1_i;
	output reg 	[DATA_WIDTH-1:0] 	param_b2_i;
	output reg 	[DATA_WIDTH-1:0] 	param_max_i;
	output reg 	[DATA_WIDTH-1:0] 	param_min_i;

	input wire						tready_o;
	
	output reg 					 	data_valid_i;
	output reg 	[CHN_WIDTH-1:0] 	data_chn_i;
	output reg 	[DATA_WIDTH-1:0] 	data_fdb_i;
	output reg 	[DATA_WIDTH-1:0] 	data_ref_i;
	
	input wire					 	u_valid_o;
	input wire [CHN_WIDTH-1:0]		u_chn_o;
	input wire [DATA_WIDTH-1:0]		u_data_o;
	
//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
	reg 	[5:0]				cnt_cycle;
	reg 					 	param_valid;
	reg 	[CHN_WIDTH-1:0] 	param_chn;

	reg 						data_load;
	reg 	[CHN_WIDTH:0]		data_cycle;

	reg 	[DATA_WIDTH-1:0]	u_data_ch0;
	reg 	[DATA_WIDTH-1:0]	u_data_ch1;
	reg 	[DATA_WIDTH-1:0]	u_data_ch2;

//**********************************************************************
// --- Main core
//**********************************************************************
// --- input parameter setting---
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
			param_valid <= ((cnt_cycle >= 5) && (cnt_cycle < NUM_CHN+5)) ? 1'b1:1'b0;
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
				param_a1_i <= 128;
				param_a2_i <= 64;
				param_a3_i <= 64;
				param_b0_i <= 26;
				param_b1_i <= 13;
				param_b2_i <= 13;
				param_max_i <= 1000;
				param_min_i <= -1000;
			end
			1: begin
				param_a1_i <= 127;
				param_a2_i <= 63;
				param_a3_i <= 63;
				param_b0_i <= 25;
				param_b1_i <= 12;
				param_b2_i <= 12;
				param_max_i <= 200;
				param_min_i <= -200;
			end
			2: begin
				param_a1_i <= 127;
				param_a2_i <= 50;
				param_a3_i <= 25;
				param_b0_i <= 25;
				param_b1_i <= 12;
				param_b2_i <= 12;
				param_max_i <= 300;
				param_min_i <= -300;
			end
			default: begin
				param_a1_i <= 127;
				param_a2_i <= 50;
				param_a3_i <= 25;
				param_b0_i <= 25;
				param_b1_i <= 12;
				param_b2_i <= 12;
				param_max_i <= 300;
				param_min_i <= -300;
			end
		endcase
	end
	
	
// ---generate data input --- 
	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			data_load <= 0;
		end
		else begin
			data_load <= (cnt_cycle >= 10)? 1'b1:1'b0;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			data_cycle <= NUM_CHN;
		end
		else if(data_load & tready_o) begin
			if(data_cycle == NUM_CHN) 
				data_cycle <= 0;
			else 
				data_cycle <= data_cycle + 1;
		end
	end

	
	always @(*) begin
		if(data_cycle == NUM_CHN) begin
			data_valid_i <= 1'b0;
			data_chn_i <= NUM_CHN-1;
			data_fdb_i <= 0;
			data_ref_i <= 800;
		end
		else if(data_cycle == 0) begin
			data_valid_i <= 1'b1;
			data_chn_i <= 0;
			data_fdb_i <= u_data_ch0;
			data_ref_i <= 800;
		end
		else if(data_cycle == 1)  begin
			data_valid_i <= 1'b1;
			data_chn_i <= 1;
			data_fdb_i <= u_data_ch1;
			data_ref_i <= 800;
		end
		else begin
			data_valid_i <= 1'b1;
			data_chn_i <= data_cycle;
			data_fdb_i <= u_data_ch2;
			data_ref_i <= 800;
		end
			
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			u_data_ch0 <= 0;
			u_data_ch1 <= 0;
			u_data_ch2 <= 0;
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
	end



endmodule