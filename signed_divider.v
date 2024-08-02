//**********************************************************************
//  Project: 
//  File: signed_divider.v
//  Description: Calculate the division of two signed 16-bit integers
//  Author: Ruiqi Tang
//  Timestamp:
//----------------------------------------------------------------------
// Code Revision History:
// Ver:     | Author    | Mod. Date     | Changes Made:
// v1.0.0   | R.T.      | 2024/05/29    | Initial version
//**********************************************************************

module signed_divider (
    input signed [15:0] A,   // 16-bit signed integer input A
    input signed [15:0] B,   // 16-bit signed integer input B
    output reg [19:0] Y     // 20-bit output: 1 bit sign + 9 bits integer + 10 bits fractional
);

reg signed [31:0] dividend;
reg signed [31:0] divisor;
reg signed [31:0] quotient;
reg [31:0] remainder;
reg [9:0] fractional;
reg [1:0] sign;

// Always block for division
always @(*) begin
    sign = 0;
    dividend = A;
    divisor = B;

    // Determine the sign of the result
    if (A < 0) sign = sign ^ 1;
    if (B < 0) sign = sign ^ 1;

    // Take absolute value for division
    dividend = (A < 0) ? -A : A;
    divisor = (B < 0) ? -B : B;

    // Ensure divisor is not zero
    if (divisor == 0) begin
        quotient = 0;
        fractional = 0;
        remainder = 0;
    end else begin
        // Perform integer division
        quotient = dividend / divisor;

        // Determine remainder and perform fixed-point fractional calculation
        remainder = dividend % divisor;
        fractional = (remainder << 10) / divisor;
    end

    // Construct the final 20-bit Quotient
    Y = {sign, quotient[8:0], fractional[9:0]};
end

endmodule