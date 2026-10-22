`timescale 1ns/1ps
module testbench ();

reg clk;
reg clr;
reg en ;
reg d  ;
wire q;

initial begin
    clr = 1'b1;     // 初始复位，所有输入初始化
    en  = 1'b0;
    clk = 0;
    d   = 0;

    #10;            // 写入  
    clr = 1'b0;
    en  = 1'b1;
    d   = 1'b1;
    #10 d = 1'b0;
    #10 d = 1'b1;

    #10;            //读取
    en = 1'b0;
    d  = 1'b0;

    #10 clr = 1'b1; //异步清零
    #50 $finish;
end

always #5 clk = ~clk;   //生成时钟

dff u_dff(              //模块例化
    .clk(clk),
    .clr(clr),
    .en(en),
    .d(d),
    .q(q)
);
endmodule