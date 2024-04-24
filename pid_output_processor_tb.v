`timescale 1ns / 1ns

module PID_output_processor_tb;

    //Parameters
    parameter  DATA_WIDTH = 16;
    parameter  NUM_CHN = 4;
    localparam CHN_WIDTH = 3;
    parameter  RPM_MAX = 1500;
    parameter  CLK_FREQ = 27_000_000;
    parameter  PWM_FREQ = 100_000;

    //Test signals
    reg clk;
    reg rstn;
    reg clk_pwm;
    reg u_valid_o;
    reg [CHN_WIDTH-1:0] u_chn_o;
    reg [DATA_WIDTH-1:0] u_data_o;

    reg [31:0] count;

    wire motor_0_in_1;
    wire motor_0_in_2;
    wire motor_1_in_1;
    wire motor_1_in_2;
    wire motor_2_in_1;
    wire motor_2_in_2;
    wire motor_3_in_1;
    wire motor_3_in_2;

    //Instantiate unit under test
    PID_output_processor uut(
        .clk(clk), .rstn(rstn), .u_valid_o(u_valid_o), .u_chn_o(u_chn_o), .u_data_o(u_data_o),
        .motor_0_in_1(motor_0_in_1), .motor_0_in_2(motor_0_in_2), .motor_1_in_1(motor_1_in_1), 
        .motor_1_in_2(motor_1_in_2), .motor_2_in_1(motor_2_in_1), .motor_2_in_2(motor_2_in_2),
        .motor_3_in_1(motor_3_in_1), .motor_3_in_2(motor_3_in_2));

    //Initial conditions
    initial begin

        //Initialize simulation
        rstn = 0;
        clk = 0;
        clk_pwm = 0;

        count = 0;

        //Reset
        #10 rstn = 1;

        //Time tick and testing
        forever begin
            #10 clk = ~clk;
            count = count + 1;
            if (count == 270) begin
                clk_pwm = ~clk_pwm;
                count = 0;
            end
        end
    end

    initial begin
        //Test sequence
        u_valid_o = 0;
        u_chn_o = 0;
        u_data_o = 16'h0000;
        #100;

        //Following sequence generates appropriate u_valid_o, u_chn_o, u_data_o signals
        u_valid_o = 1;
        
        //Test sequence for channel0
        u_chn_o = 0;
        u_data_o = 16'd150; //test data for channel0
        #20;
        
        //Test sequence for channel1
        u_chn_o = 1;
        u_data_o = 16'd500; //test data for channel1
        #20;
        
        //Test sequence for channel2
        u_chn_o = 2;
        u_data_o = 16'd700; //test data for channel2
        #20;
        
        //Test sequence for channel3
        u_chn_o = 3;
        u_data_o = 16'd1000; //test data for channel3
        #20;

        u_valid_o = 0;
        #54000;


        u_valid_o = 1;
        
        //Test sequence for channel0
        u_chn_o = 0;
        u_data_o = 16'd155; //test data for channel0
        #20;
        
        //Test sequence for channel1
        u_chn_o = 1;
        u_data_o = 16'd505; //test data for channel1
        #20;
        
        //Test sequence for channel2
        u_chn_o = 2;
        u_data_o = 16'd705; //test data for channel2
        #20;
        
        //Test sequence for channel3
        u_chn_o = 3;
        u_data_o = 16'd1005; //test data for channel3
        #20;

        u_valid_o = 0;
        
        #20000;

        u_valid_o = 1;
        
        //Test sequence for channel0
        u_chn_o = 0;
        u_data_o = 16'd200; //test data for channel0
        #20;
        
        //Test sequence for channel1
        u_chn_o = 1;
        u_data_o = 16'd600; //test data for channel1
        #20;
        
        //Test sequence for channel2
        u_chn_o = 2;
        u_data_o = 16'd800; //test data for channel2
        #20;
        
        //Test sequence for channel3
        u_chn_o = 3;
        u_data_o = 16'd1200; //test data for channel3
        #20;

        u_valid_o = 0;
        #54000;

        u_valid_o = 1;
        
        //Test sequence for channel0
        u_chn_o = 0;
        u_data_o = 16'd355; //test data for channel0
        #20;
        
        //Test sequence for channel1
        u_chn_o = 1;
        u_data_o = 16'd105; //test data for channel1
        #20;
        
        //Test sequence for channel2
        u_chn_o = 2;
        u_data_o = 16'd1005; //test data for channel2
        #20;
        
        //Test sequence for channel3
        u_chn_o = 3;
        u_data_o = 16'd705; //test data for channel3
        #20;

        u_valid_o = 0;
        
        #2000;

        u_valid_o = 1;
    
        //Test sequence for channel0
        u_chn_o = 0;
        u_data_o = -16'd155; //test data for channel0
        #20;
        
        //Test sequence for channel1
        u_chn_o = 1;
        u_data_o = -16'd505; //test data for channel1
        #20;
        
        //Test sequence for channel2
        u_chn_o = 2;
        u_data_o = -16'd705; //test data for channel2
        #20;
        
        //Test sequence for channel3
        u_chn_o = 3;
        u_data_o = -16'd1005; //test data for channel3
        #20;

        u_valid_o = 0;
        
        #60000;
        $finish;
    end
        



endmodule
