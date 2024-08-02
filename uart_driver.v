//**********************************************************************
//  Project: 
//  File: UART_driver.v
//  Description: Send friction factor data through UART
//  Author: Ruiqi Tang
//  Modified from: ppqppl (https://www.cnblogs.com/ppqppl/articles/17461611.html)
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/05/29    | Initial version
//**********************************************************************

module UART_driver(
    clk,
    rstn,

    rpm0_ready,
    rpm1_ready,
    rpm2_ready,
    rpm3_ready,

    rpm0_data_o,
    rpm1_data_o,
    rpm2_data_o,
    rpm3_data_o,

    u_valid_o,
    u_chn_o,
    u_data_o,

    stop,

    uart_tx
);

//**********************************************************************
// --- Parameter
//**********************************************************************
    parameter CLK_FREQ = 27_000_000;
    parameter BAUD_RATE = 115200;
    localparam  CHN_WIDTH = 3;
    parameter DATA_WIDTH = 16;
    parameter OUTPUT_RATE = 4*2;

//**********************************************************************
// --- Input/Output Declaration
//**********************************************************************
    input  wire                     clk;
    input  wire                     rstn;

    input wire                      rpm0_ready;
    input wire                      rpm1_ready;
    input wire                      rpm2_ready;
    input wire                      rpm3_ready;

    input wire  [DATA_WIDTH-1:0]    rpm0_data_o;
    input wire  [DATA_WIDTH-1:0]    rpm1_data_o;
    input wire  [DATA_WIDTH-1:0]    rpm2_data_o;
    input wire  [DATA_WIDTH-1:0]    rpm3_data_o;
    input wire                      u_valid_o;
    input wire  [CHN_WIDTH-1:0]     u_chn_o;
    input wire  [DATA_WIDTH-1:0]    u_data_o;

    input wire  [3:0]               stop;

    output wire                     uart_tx;
//**********************************************************************
// --- Internal Signal Declaration
//**********************************************************************
    reg     [31:0]          cnt_clk;
    reg     [3:0]           xcnt;
    reg     [2:0]           cnt_chn;

    reg     [DATA_WIDTH-1:0]    rpm_data_ch0;
    reg     [DATA_WIDTH-1:0]    rpm_data_ch1;
    reg     [DATA_WIDTH-1:0]    rpm_data_ch2;
    reg     [DATA_WIDTH-1:0]    rpm_data_ch3;

    reg     [DATA_WIDTH-1:0]    u_data_ch0;
    reg     [DATA_WIDTH-1:0]    u_data_ch1;
    reg     [DATA_WIDTH-1:0]    u_data_ch2;
    reg     [DATA_WIDTH-1:0]    u_data_ch3;

    wire    [19:0]          friction_ch0;
    wire    [19:0]          friction_ch1;
    wire    [19:0]          friction_ch2;
    wire    [19:0]          friction_ch3;

    reg     [19:0]          data_out;
    reg     [7:0]           data;

    wire                    flag_tx_begin;
    wire                    tx_done;
    wire                    flag_invalid_data;

    wire    [8:0]           int_part;
    wire    [9:0]           frac_part;

    reg     [3:0]           data_hund;
    reg     [3:0]           data_tens;
    reg     [3:0]           data_ones;
    reg     [3:0]           data_tenths;
    reg     [3:0]           data_hundths;
    reg     [3:0]           data_thouths;

//**********************************************************************
// --- Main Core
//**********************************************************************
// --- handle pid_output and rpm_output ----
    // rpm sample & holding
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rpm_data_ch0 <= 0;
            rpm_data_ch1 <= 0;
            rpm_data_ch2 <= 0;
            rpm_data_ch3 <= 0;
        end
        else begin
            if (rpm0_ready == 1'b1)
                rpm_data_ch0 <= rpm0_data_o;
            else
                rpm_data_ch0 <= rpm_data_ch0;

            if (rpm1_ready == 1'b1)
                rpm_data_ch1 <= rpm1_data_o;
            else
                rpm_data_ch1 <= rpm_data_ch1;

            if (rpm2_ready == 1'b1)
                rpm_data_ch2 <= rpm2_data_o;
            else
                rpm_data_ch2 <= rpm_data_ch2;
                
            if (rpm3_ready == 1'b1)
                rpm_data_ch3 <= rpm3_data_o;
            else
                rpm_data_ch3 <= rpm_data_ch3;
        end
    end
    // handle the PID output data
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

// --- generate data_out ---
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_chn <= 0;
            data_out <= 0;
        end
        else begin
            case(cnt_chn)
                0:  data_out <= stop[0] ? 0 : friction_ch2;
                1:  data_out <= stop[1] ? 0 : friction_ch3;
                2:  data_out <= stop[2] ? 0 : friction_ch2;
                3:  data_out <= stop[3] ? 0 : friction_ch3;
                // 0 : data_out <= rpm_data_ch2 < 9'b111111111 ? {1'd0, rpm_data_ch2[8:0], 10'd0}: {1'd0, 9'b111111111, 10'd0};
                // 1 : data_out <= u_data_ch2 < 9'b111111111 ? {1'd0, u_data_ch2[8:0], 10'd0}: {1'd0, 9'b111111111, 10'd0};
                // 2 : data_out <= friction_ch2;
                // 1 : data_out <= test < 9'b111111111 ? {1'd0, test[8:0], 10'd0}: {1'd0, 9'b111111111, 10'd0};
                
                default: data_out <= 0;
            endcase

            if(xcnt == 4'd10) begin
                if(cnt_chn==1)
                    cnt_chn <= 0;
                else
                    cnt_chn <= cnt_chn + 1;
            end
        end
    end

// --- uart_tx ---
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            xcnt <= 0;
        else if(tx_done)
            xcnt <= xcnt + 1;
        else if(xcnt == 4'd10)
            xcnt <= 0;
        else
            xcnt <= xcnt;
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt_clk <= 0;
        end
        else if (flag_tx_begin) begin
            cnt_clk <= 0;
        end
        else begin
            cnt_clk <= cnt_clk + 1;
        end
    end

    assign flag_tx_begin = (cnt_clk == CLK_FREQ/(11*OUTPUT_RATE) - 1);
    assign flag_invalid_data = data_hund == 0 && data_tens == 0 && data_ones == 0 && data_tenths == 0 && data_hundths == 0 && data_thouths == 0;

    assign int_part = data_out[18:10];
    assign frac_part = data_out[9:0];

    // calculate data
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_hund <= 0;
            data_tens <= 0;
            data_ones <= 0;
            data_tenths <= 0;
            data_hundths <= 0;
            data_thouths <= 0;
        end
        else begin
            data_hund <= (int_part / 100) % 10;
            data_tens <= (int_part / 10) % 10;
            data_ones <= int_part % 10;
            data_tenths <= ((frac_part * 10) / 1024) % 10;
            data_hundths <= ((frac_part * 100) / 1024) % 10;
            data_thouths <= ((frac_part * 1000) / 1024) % 10;
        end
    end

    // generate data
    always @(*) begin
        case (xcnt)
            0:  data = hex_data({1'd0, cnt_chn});
            1:  data = data_out[19] ? "-" : "+";
            2:  data = hex_data(data_hund);
            3:  data = hex_data(data_tens);
            4:  data = hex_data(data_ones);
            5:  data = ".";
            6:  data = hex_data(data_tenths);
            7:  data = hex_data(data_hundths);
            8:  data = hex_data(data_thouths);
            9:  data = (cnt_chn == 3'd1)? "\n" : " ";
            10: data = (cnt_chn == 3'd1)? "\r" : " ";
            default: data = 6'h30; //"0"
        endcase
    end

//**********************************************************************
// --- function: hex_data 
// --- Description: input 4 bit BCD, output 7 bit ASCII
//**********************************************************************
    function [7:0] hex_data;
        input [3:0] data_i;
        begin
            case(data_i)
                4'd0: hex_data = 6'h30;
                4'd1: hex_data = 6'h31;
                4'd2: hex_data = 6'h32;
                4'd3: hex_data = 6'h33;
                4'd4: hex_data = 6'h34;
                4'd5: hex_data = 6'h35;
                4'd6: hex_data = 6'h36;
                4'd7: hex_data = 6'h37;
                4'd8: hex_data = 6'h38;
                4'd9: hex_data = 6'h39;
                4'd10: hex_data = 6'h39;
                4'd11: hex_data = 6'h39;
                4'd12: hex_data = 6'h39;
                4'd13: hex_data = 6'h39;
                4'd14: hex_data = 6'h39;
                4'd15: hex_data = 6'h39;
                default: hex_data = 6'h30;
            endcase
        end
    endfunction

//**********************************************************************
// --- module: UART_send
// --- Description: send data via UART
//**********************************************************************
    UART_send UART_send_inst(
        .clk        (clk),
        .rstn       (rstn),
        .tx_flag_i  (flag_tx_begin),
        .tx_data_i  (data),
        .tx_done    (tx_done),
        .uart_tx    (uart_tx)
    );

//**********************************************************************
// --- module: signed_divider
// --- Description: Calculate friction factor = "PID output" / "RPM output"
//**********************************************************************
    signed_divider signed_divider_inst0(
        .A(u_data_ch0),
        .B(rpm_data_ch0),
        .Y(friction_ch0)
    );

    signed_divider signed_divider_inst1(
        .A(u_data_ch1),
        .B(rpm_data_ch1),
        .Y(friction_ch1)
    );

    signed_divider signed_divider_inst2(
        .A(u_data_ch2),
        .B(rpm_data_ch2),
        .Y(friction_ch2)
    );

    signed_divider signed_divider_inst3(
        .A(u_data_ch3),
        .B(rpm_data_ch3),
        .Y(friction_ch3)
    );

endmodule