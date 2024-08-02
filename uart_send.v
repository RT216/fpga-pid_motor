//**********************************************************************
//  Project: TDPS
//  File: UART_send.v
//  Description: Send 8-bit data through UART
//  Author: Ruiqi Tang
//  Modified from: ppqppl (https://www.cnblogs.com/ppqppl/articles/17461611.html)
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/05/15    | Initial version
//**********************************************************************

module UART_send(
    clk,
    rstn,
    
    tx_flag_i,
    tx_data_i,

    tx_done,

    uart_tx
);

//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter   CLK_FREQ = 27_000_000;
    parameter   BAUD_RATE = 115200;

    localparam  BAUD_CLK = CLK_FREQ/BAUD_RATE;
//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input wire                      clk;
    input wire                      rstn;

    
    input wire [7:0]                tx_data_i;
    input wire                      tx_flag_i;
    output reg                      uart_tx;
    output reg                      tx_done;
    
//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    reg                             tx_en;
    reg                             flag_bit;
    reg         [8:0]               cnt_baud;
    reg         [3:0]               cnt_bit;

//**********************************************************************
// --- Main Core
//**********************************************************************
    // enable tx
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            tx_en <= 1'b0;
        end
        else if (cnt_bit == 4'd9 && flag_bit == 1'b1) begin
            tx_en <= 1'b0;
        end
        else if (tx_flag_i) begin
            tx_en <= 1'b1;
        end
    end

    // baud counter
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_baud <= 9'd0;
        end
        else if (cnt_baud == BAUD_CLK-1 || tx_en == 0) begin
            cnt_baud <= 9'd0;
        end
        else begin
            cnt_baud <= cnt_baud + 9'd1;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            flag_bit <= 1'b0;
        end
        else if (cnt_baud == 9'd1) begin
            flag_bit <= 1'b1;
        end
        else begin
            flag_bit <= 1'b0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_bit <= 4'd0;
            tx_done <= 1'd0;
        end
        else if (cnt_bit == 4'd9 && flag_bit == 1'b1) begin
            cnt_bit <= 4'd0;
            tx_done <= 1'b1;
        end
        else if (flag_bit == 1'b1 && tx_en == 1'b1) begin
            cnt_bit <= cnt_bit + 4'd1;
            tx_done <= 1'b0;
        end
        else begin
            cnt_bit <= cnt_bit;
            tx_done <= 1'b0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            uart_tx <= 1'd1;
        end
        else if (flag_bit == 1'b1) begin
            case (cnt_bit)
                0:  uart_tx <= 1'd0;
                1:  uart_tx <= tx_data_i[0];
                2:  uart_tx <= tx_data_i[1];
                3:  uart_tx <= tx_data_i[2];
                4:  uart_tx <= tx_data_i[3];
                5:  uart_tx <= tx_data_i[4];
                6:  uart_tx <= tx_data_i[5];
                7:  uart_tx <= tx_data_i[6];
                8:  uart_tx <= tx_data_i[7];
                9:  uart_tx <= 1'd1;
                default : uart_tx <= 1'd1;     
            endcase
        end
    end


endmodule
