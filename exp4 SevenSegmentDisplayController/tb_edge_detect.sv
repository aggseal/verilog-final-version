`timescale 1ns/1ps

module tb_edge_detect;
    reg clk;
    reg rst;
    reg signal_in;

    wire rise_pulse;
    reg [7:0] rise_count;

    edge_detect u_edge_detect (
        .clk(clk),
        .rst(rst),
        .signal_in(signal_in),
        .rise_pulse(rise_pulse)
    );

    always #5 clk = ~clk;

    // 统计边沿检测器输出的上升沿脉冲数
    always @(posedge clk or posedge rst) begin
        if (rst)
            rise_count <= 8'd0;
        else if (rise_pulse)
            rise_count <= rise_count + 1'b1;
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        signal_in = 1'b0;
        rise_count = 8'd0;

        #20 rst = 1'b0;

        // 第一次输入上升沿，然后回到低电平
        @(negedge clk); signal_in = 1'b1;
        repeat (5) @(negedge clk);
        signal_in = 1'b0;
        repeat (5) @(negedge clk);

        // 第二次输入上升沿
        signal_in = 1'b1;
        repeat (5) @(negedge clk);
        signal_in = 1'b0;
        repeat (4) @(negedge clk);

        if (rise_count == 8'd2)
            $display("PASS: two rising edges produced two pulses.");
        else
            $display("FAIL: expected 2 pulses, rise_count=%0d", rise_count);
        $finish;
    end
endmodule