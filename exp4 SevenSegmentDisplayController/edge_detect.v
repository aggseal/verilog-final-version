module edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire signal_in,
    output wire rise_pulse
);

reg signal_0;
reg signal_1;

//用两级寄存器依次采样 signal_in，并在 rst 时异步清零
always @(posedge clk or posedge rst) begin
    if (rst) begin
        signal_0 <= 0;
        signal_1 <= 0;
    end else begin
        signal_0 <= signal_in;
        signal_1 <= signal_0;
    end
end
assign rise_pulse = signal_0 && ~signal_1;

endmodule