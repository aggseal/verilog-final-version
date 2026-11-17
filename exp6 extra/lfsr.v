// 16 位 LFSR；在命中后 advance 一个状态，作为下一只地鼠的位置来源
module lfsr (
    input  wire        clk,
    input  wire        rst,
    input  wire        advance,
    output reg  [15:0] random_value
);

wire feedback = random_value[15] ^ random_value[13] ^ random_value[12] ^ random_value[10];

always @(posedge clk or posedge rst) begin
    if (rst)
        random_value <= 16'hACE1;   //随机数种子
    else if (advance) begin
        random_value <= {random_value[14:0], feedback};    //左移
        if (random_value == 16'd0)
            random_value <= 16'hACE1;
    end
end

endmodule
