module Int_Divider(
    input [31:0] numerator,
    input [31:0] denominator,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);
    integer i;
    always @(numerator, denominator)
    begin
        quotient = 0;
        remainder = numerator;
        for(i = 31; i >= 0; i = i - 1)
        begin
            if (remainder >= (denominator << i))
            begin
                remainder = remainder - (denominator << i);
                quotient = quotient | (1 << i);
            end
        end
    end
endmodule
