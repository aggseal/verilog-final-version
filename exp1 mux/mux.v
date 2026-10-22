module mux (
    input  wire       en,
    input  wire       mux_sel,
    input  wire [3:0] input_a,
    input  wire [3:0] input_b,
    output reg  [3:0] output_c
);
    always @(*) begin
        if (en == 0)  output_c = 4'b1111;
        else if (mux_sel == 1)
        output_c = input_a - input_b;
        else
        output_c = input_a + input_b;
    end
endmodule