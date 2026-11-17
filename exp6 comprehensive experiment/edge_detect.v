// edge_detect : 检测上升沿；输出一个时钟周期的 rise_pulse
module edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire signal_in,
    output wire rise_pulse
);

reg signal_0;
reg signal_1;

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        signal_0 <= 1'b0;
        signal_1 <= 1'b0;
    end
    else begin
        signal_1 <= signal_in;
        signal_0 <= signal_1;
    end
end

assign rise_pulse = signal_1 && ~signal_0; // 上升沿拉高脉冲

endmodule
