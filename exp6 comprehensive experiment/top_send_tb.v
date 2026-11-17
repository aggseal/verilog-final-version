`timescale 1ns / 1ps

module top_send_tb;

reg clk;
reg rst;
reg key_s2;
reg uart_rx;

wire uart_tx;
wire [7:0] led_en;
wire [7:0] led_cx0;
wire [7:0] led_cx1;

initial clk = 1'b0;
always #5 clk = ~clk;  // 100 MHz 时钟

top dut (
    .clk(clk),
    .rst(rst),
    .key_s2(key_s2),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .led_en(led_en),
    .led_cx0(led_cx0),
    .led_cx1(led_cx1)
);

initial begin
    rst = 1'b1;
    key_s2 = 1'b0;
    uart_rx = 1'b1;       // UART 接收端空闲为高

    #100;
    rst = 1'b0;

    #100;
    key_s2 = 1'b1;        // 模拟按下 S2
    #10100000;            // 保持 10.1 ms，超过按键消抖时间
    key_s2 = 1'b0;

    #30000000;            // 留出时间发送整条消息
    $finish;
end

endmodule