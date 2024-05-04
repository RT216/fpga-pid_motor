`timescale 1ns / 1ns

module UART_controller_tb();

    //Parameters
    parameter  DATA_WIDTH = 16;
    parameter  NUM_CHN = 4;
    localparam CHN_WIDTH = 3;
    parameter  CLK_FREQ = 27_000_000;
    parameter   BAUD_RATE = 115200;

    localparam  BAUD_CLK = CLK_FREQ/BAUD_RATE;
    //Test signals
    reg         clk;
    reg         rstn;

    reg         rx;

    wire                    tr_valid_o;
    wire [CHN_WIDTH-1:0]    tr_chn_o;
    wire [DATA_WIDTH-1:0]   tr_data_o;

    //Instantiate unit under test
    UART_controller uut(
        .clk(clk), .rstn(rstn), .uart_rx(rx), .tr_valid_o(tr_valid_o),
        .tr_chn_o(tr_chn_o), .tr_data_o(tr_data_o)
    );

    //Initial conditions
    initial begin

        //Initialize simulation
        rstn <= 0;
        clk = 0;

        //Reset
        #201 rstn <= 1;

        //Time tick and testing
        forever begin
            #10 clk = ~clk;
        end
    end

    //Simulate sending signals
    initial begin
        #200
        rx_bit(8'b1001_0001); //set rpm
        rx_bit(8'b0001_0001); //00
        rx_bit(8'b1010_1000); //13'b 1_0001_1010_1000 -> -3672
        rx_bit(8'b0010_1001); //01
        rx_bit(8'b1010_1001); //13'b 0_1001_1010_1001 -> 2473
        rx_bit(8'b0101_0101); //10
        rx_bit(8'b0000_1010); //13'b 1_0101_0000_1010 -> -2806
        rx_bit(8'b0111_0101); //11
        rx_bit(8'b1111_1111); //13'b 1_0101_1111_1111 -> -2561
        rx_bit(8'b1111_1111); //return
        rx_bit(8'b1001_0001); //set rpm
        rx_bit(8'b0000_0001); //00
        rx_bit(8'b1010_1000); //13'b 0_0001_1010_1000 -> 424
        rx_bit(8'b1111_1111); //return
    end

    //define a task to send signals
    task rx_bit(
        input [7:0] data
    );
        integer i;

        for(i = 0; i < 10; i = i + 1) begin
            case (i)
                0: rx <= 1'b0;
                1: rx <= data[0];
                2: rx <= data[1];
                3: rx <= data[2];
                4: rx <= data[3];
                5: rx <= data[4];
                6: rx <= data[5];
                7: rx <= data[6];
                8: rx <= data[7];
                9: rx <= 1'b1;
            endcase
            #(BAUD_CLK*20); //wait for BAUD_CLK clks
        end 
    endtask

endmodule