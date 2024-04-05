//**********************************************************************
//  Project: TDPS
//  File: top_tv.v
//  Description: testbench for top module
//  Author: 
//  Timestamp: 
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v0.1.0   | R.T       | 2024/03/10    | Initial version
//**********************************************************************

`timescale 1ns/10ps

module top_tb;

parameter CLK_PERIOD = 10;

reg CLK;
reg RSTN;

initial begin
    CLK = 1'b0;
    RSTN = 1'b0;
end

/*iverilog*/
// initial begin
//  $dumpfile("wave.vcd");
//  $dumpvars(0, top_tb);
// end
/*iverilog*/

initial begin
    #(CLK_PERIOD * 10)
        RSTN = 1'b1;
    #1000
        $stop;
end

always @(CLK)
    #(CLK_PERIOD/2.0) CLK<= !CLK;

top top_u0(
    //inputs
    .clk(CLK),
    .rstn(RSTN),
    //outputs
    .u_valid_o(u_valid_o),
    .u_chn_o(u_chn_o),
    .u_data_o(u_data_o)
);

endmodule