//**********************************************************************
//  Project: TDPS
//  File: uart_recv.v
//  Description: receive data from uart rx
//  Author: Ruiqi Tang          
//  Modified from: ppqppl (https://www.cnblogs.com/ppqppl/articles/17461611.html)
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/04/08    | Initial version
// v1.0.1   | R.T       | 2024/05/04    | Tested set_rpm func.
//**********************************************************************

module UART_recv(
    clk,
    rstn,
    uart_rx,
    rx_data_valid_o,
    rx_data_o
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

    input wire                      uart_rx;

    output reg                      rx_data_valid_o;
    output reg [7:0]                rx_data_o;

//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    reg                             rx_en;          // enable to receive data
    reg                             start_flag;     // detect start bit
    reg                             bit_flag;       // indicate each bit
    reg                             stop_flag;      // indicate the end of receiving

    //triple-synchronizing
    reg                             rx_reg1;
    reg                             rx_reg2;
    reg                             rx_reg3;

    reg [8:0]                       cnt_baud;
    reg [3:0]                       cnt_bit;
    reg [7:0]                       data_reg;

//**********************************************************************
// --- Main core
//**********************************************************************

// --- triple-synchronizing
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rx_reg1 <= 1'b1;
            rx_reg2 <= 1'b1;
            rx_reg3 <= 1'b1;
        end
        else begin
            rx_reg1 <= uart_rx;
            rx_reg2 <= rx_reg1;
            rx_reg3 <= rx_reg2;
        end
    end

// --- receive data
    // --- detect the start bit
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            start_flag <= 1'b0;
        end
        else if(rx_reg3 && ~rx_reg2) begin
            start_flag <= 1'b1;
        end
        else begin
            start_flag <= 1'b0;
        end        
    end

    // --- enable to receive data
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rx_en <= 1'b0;
        end
        else if(start_flag) begin
            rx_en <= 1'b1;
        end
        else if(cnt_bit == 4'd8 && bit_flag) begin // received 8 bits
            rx_en <= 1'b0;
        end
    end

    // --- counter for baud rate
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_baud <= 9'd0;
        end
        else if(rx_en) begin
            if(cnt_baud == BAUD_CLK-1) begin
                cnt_baud <= 9'd0;
            end
            else begin
                cnt_baud <= cnt_baud + 1;
            end
        end
        else begin
            cnt_baud <= 9'd0;
        end
    end

    // --- indicator for each bit
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            bit_flag <= 1'b0;
        end
        else if(cnt_baud == BAUD_CLK/2 - 1'b1) begin
            bit_flag <= 1'b1;
        end
        else begin
            bit_flag <= 1'b0;
        end
    end

    // --- counter for each bit
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_bit <= 4'd0;
        end
        else if(bit_flag) begin
            if(cnt_bit == 4'd8) begin
                cnt_bit <= 4'd0;
            end
            else begin
                cnt_bit <= cnt_bit + 1;
            end
        end
    end

    // --- receive data
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_reg <= 8'd0;
        end
        else if(bit_flag && cnt_bit >= 4'd1 && cnt_bit <= 4'd8) begin
            data_reg <= {rx_reg3, data_reg[7:1]}; // first bit is the LSB
        end
    end

    // --- stop bit
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            stop_flag <= 1'b0;
        end
        else if(cnt_bit == 4'd8 && bit_flag) begin
            stop_flag <= 1'b1;
        end
        else begin
            stop_flag <= 1'b0;
        end
    end

// --- output data
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rx_data_valid_o <= 1'b0;
            rx_data_o <= 8'd0;
        end
        else if(stop_flag) begin
            rx_data_valid_o <= 1'b1;
            rx_data_o <= data_reg;
        end
        else begin
            rx_data_valid_o <= 1'b0;
            rx_data_o <= 8'd0;
        end
    end

endmodule