//**********************************************************************
//  Project: TDPS
//  File: uart_controller.v
//  Description: decode the received data to target rpm
//  Author: Ruiqi Tang          
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/04/08    | Initial version
// v1.0.1   | R.T       | 2024/05/04    | Tested set_rpm func.
//**********************************************************************

module UART_controller (
    clk,
    rstn,

    uart_rx,

    tr_valid_o,
    tr_chn_o,
    tr_data_o
);

//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter DATA_WIDTH = 16;

    parameter NUM_CHN = 4;
    localparam CHN_WIDTH = 3;

//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input wire                      clk;
    input wire                      rstn;

    input wire                      uart_rx;

    output reg                      tr_valid_o;
    output reg  [CHN_WIDTH-1:0]     tr_chn_o;
    output reg  [DATA_WIDTH-1:0]    tr_data_o;

//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    wire                            rx_data_valid_o;
    wire    [7:0]                   rx_data_o;

    reg     [3:0]                   current_state;
    reg     [3:0]                   next_state;

    reg     [DATA_WIDTH-1:0]        current_rx_number;
    reg     [DATA_WIDTH-1:0]        next_rx_number;
    reg     [CHN_WIDTH-1:0]         current_rx_chn;
    reg     [CHN_WIDTH-1:0]         next_rx_chn;
    reg                             current_rx_valid;
    reg                             next_rx_valid;

    reg     [DATA_WIDTH-1:0]        target_rpm_ch0;
    reg     [DATA_WIDTH-1:0]        target_rpm_ch1;
    reg     [DATA_WIDTH-1:0]        target_rpm_ch2;
    reg     [DATA_WIDTH-1:0]        target_rpm_ch3;


//**********************************************************************
// --- module: UART_recv
// --- Description: receive data from uart rx
//**********************************************************************
    UART_recv UART_recv_inst0 (
        .clk                (clk            ),
        .rstn               (rstn           ),
        .uart_rx            (uart_rx        ),
        .rx_data_valid_o    (rx_data_valid_o),
        .rx_data_o          (rx_data_o      )
    );

//**********************************************************************
// UART message format
//  1. [command] set_rpm 8'b1001_0001
//          > enter the rpm setting mode
//  2. [number] set high 5 bits {{3'b[chn_num]}, {5'b[rpm]}}
//  3. [number] set lower 8 bits 8'b[rpm]
//  4. [command] return 8'b1111_1111
//          > return to idle mode
//**********************************************************************
    `define STATE_INIT 4'h0
    `define STATE_IDLE 4'h1     // wait for command
    `define STATE_RPMH 4'h2     // read rpm high
    `define STATE_RPML 4'h3     // read rpm low

//**********************************************************************
// --- Main core
//**********************************************************************

// update registers
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            current_state       <= `STATE_INIT;
            current_rx_chn      <= 0;
            current_rx_number   <= 0;
            current_rx_valid    <= 0;
        end
        else begin
            current_state       <= next_state;
            current_rx_chn      <= next_rx_chn;
            current_rx_number   <= next_rx_number;
            current_rx_valid    <= next_rx_valid;
        end
    end

// state transition
    always @(*) begin
        next_state = current_state;
        next_rx_chn = current_rx_chn;
        next_rx_number = current_rx_number;
        next_rx_valid = current_rx_valid;

        case (current_state)
            `STATE_INIT: begin
                next_state = `STATE_IDLE;
                next_rx_chn = 0;
                next_rx_number = 0;
                next_rx_valid = 0;
            end

            `STATE_IDLE: begin
                next_rx_chn = 0;
                next_rx_number = 0;
                next_rx_valid = 0;

                if (rx_data_valid_o) begin
                    // if recieved set_rpm command
                    if (rx_data_o == 8'b1001_0001) begin
                        next_state = `STATE_RPMH;
                    end
                    else begin
                        next_state = current_state;
                    end
                end
                else begin
                    next_state = current_state;
                end
            end

            `STATE_RPMH: begin
                next_rx_valid = 0;

                if (rx_data_valid_o) begin
                    if(rx_data_o == 8'b1111_1111) begin
                        next_state = `STATE_IDLE;
                        next_rx_chn = 0;
                        next_rx_number = 0;
                        next_rx_valid = 0;
                    end
                    else begin
                        next_state = `STATE_RPML;
                        next_rx_chn = rx_data_o[7:5];
                        next_rx_number = {{3{rx_data_o[4]}}, rx_data_o[4:0], 8'b0};
                    end
                end
                else begin
                    next_state = current_state;
                    next_rx_chn = current_rx_chn;
                    next_rx_number = current_rx_number;
                end
            end

            `STATE_RPML: begin
                if (rx_data_valid_o) begin
                    next_state = `STATE_RPMH;
                    next_rx_chn = current_rx_chn;
                    next_rx_number[7:0] = rx_data_o;
                    next_rx_valid = 1;
                end
                else begin
                    next_state = current_state;
                    next_rx_chn = current_rx_chn;
                    next_rx_number = current_rx_number;
                    next_rx_valid = current_rx_number;
                end
            end

            default: begin
                next_state = current_state;
                next_rx_chn = current_rx_chn;
                next_rx_number = current_rx_number;
                next_rx_valid = current_rx_valid;
            end
        endcase
    end

// output handle
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tr_chn_o            <= 0;
            tr_data_o           <= 0;
            tr_valid_o          <= 0;
        end
        else begin
            if (current_rx_valid) begin
                tr_chn_o        <= current_rx_chn;
                tr_data_o       <= current_rx_number;
                tr_valid_o      <= 1;
            end
            else begin
                tr_chn_o        <= 0;
                tr_data_o       <= 0;
                tr_valid_o      <= 0;
            end
        end
    end
    
endmodule
