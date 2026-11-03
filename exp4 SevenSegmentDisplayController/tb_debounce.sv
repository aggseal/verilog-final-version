`timescale 1ns/1ps

module tb_debounce;
    reg clk;
    reg rst;
    reg key_in;

    wire key_clean;
    wire rise_pulse;
    reg [7:0] clean_count;

    // 仿真时缩短稳定周期；上板设计仍使用 debounce 的默认参数
    debounce #(
        .STABLE_CYCLES(5)
    ) u_debounce (
        .clk(clk),
        .rst(rst),
        .key_in(key_in),
        .key_clean(key_clean)
    );

    edge_detect u_edge_detect (
        .clk(clk),
        .rst(rst),
        .signal_in(key_clean),
        .rise_pulse(rise_pulse)
    );

    always #5 clk = ~clk;

    always @(posedge clk or posedge rst) begin
        if (rst)
            clean_count <= 8'd0;
        else if (rise_pulse)
            clean_count <= clean_count + 1'b1;
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        key_in = 1'b0;

        #25;
        rst = 1'b0;

        // 第一次按下：抖动后稳定为高
        @(negedge clk); key_in = 1'b1;
        @(negedge clk); key_in = 1'b0;
        @(negedge clk); key_in = 1'b1;
        @(negedge clk); key_in = 1'b0;
        @(negedge clk); key_in = 1'b1;
        repeat (12) @(negedge clk);

        // 松开：抖动后稳定为低
        key_in = 1'b0;
        @(negedge clk); key_in = 1'b1;
        @(negedge clk); key_in = 1'b0;
        repeat (12) @(negedge clk);

        // 第二次按下：再次抖动后稳定为高
        key_in = 1'b1;
        @(negedge clk); key_in = 1'b0;
        @(negedge clk); key_in = 1'b1;
        @(negedge clk); key_in = 1'b0;
        @(negedge clk); key_in = 1'b1;
        repeat (12) @(negedge clk);

        repeat (3) @(negedge clk);
        if (clean_count == 8'd2)
            $display("PASS: two debounced presses counted, clean_count=%0d", clean_count);
        else
            $display("FAIL: expected 2 debounced presses, clean_count=%0d", clean_count);
        $finish;
    end
endmodule