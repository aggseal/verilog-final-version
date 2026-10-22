`timescale 1ns / 1ps

module testbench ();

reg        clk;
reg        clr;
reg        en;
reg  [7:0] d;
reg  [2:0] wsel;
reg  [2:0] rsel;
wire [7:0] q;
integer    idx;

// 产生周期为 10ns 的时钟
initial begin
    clk = 1'b0;
end

always #5 clk = ~clk;

// 仿真激励与检查
initial begin
    // 初始化输入并进行异步清零
    clr  = 1'b1;
    en   = 1'b0;
    d    = 8'h00;
    wsel = 3'd0;
    rsel = 3'd0;

    #2;
    clr = 1'b0;

    // 依次向 8 个寄存器写入不同数据
    en = 1'b1;
    for (idx = 0; idx < 8; idx = idx + 1) begin
        wsel = idx[2:0];
        d    = 8'hA0 + idx;
        @(posedge clk);
        #1;
    end

    // 依次读取并检查 8 个寄存器
    en = 1'b0;
    for (idx = 0; idx < 8; idx = idx + 1) begin
        rsel = idx[2:0];
        #1;
        if (q !== (8'hA0 + idx)) begin
            $fatal(1, "read failed: register %0d, expected %h, got %h",
                   idx, 8'hA0 + idx, q);
        end
    end

    // en=0 时尝试写入，确认寄存器 3 保持原值
    wsel = 3'd3;
    rsel = 3'd3;
    d    = 8'hFF;
    en   = 1'b0;
    @(posedge clk);
    #1;
    if (q !== 8'hA3) begin
        $fatal(1, "write-enable hold failed: expected A3, got %h", q);
    end

    // 再次异步清零，并检查全部寄存器
    #2 clr = 1'b1;
    #1;
    for (idx = 0; idx < 8; idx = idx + 1) begin
        rsel = idx[2:0];
        #1;
        if (q !== 8'h00) begin
            $fatal(1, "async clear failed: register %0d, got %h", idx, q);
        end
    end

    $display("PASS: reg8file simulation checks completed.");
    $finish;
end

// 被测试模块（DUT）例化
reg8file u_reg8file (
    .clk  (clk),
    .clr  (clr),
    .en   (en),
    .d    (d),
    .wsel (wsel),
    .rsel (rsel),
    .q    (q)
);

endmodule
