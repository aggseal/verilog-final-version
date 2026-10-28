`timescale 1ns / 1ps

module flowing_water_light_tb;

reg clk;
reg rst;
reg freq_ctrl;
reg dir_ctrl;
reg mode_sel;
wire [7:0] led;

// 终值 6 对应 cnt=0..6；终值 11 对应 cnt=0..11。
flowing_water_light #(
    .cnt_500hz(24'd6),
    .cnt_10hz(24'd11),
    .WIDTH(4)
) dut (
    .clk(clk),
    .rst(rst),
    .freq_ctrl(freq_ctrl),
    .dir_ctrl(dir_ctrl),
    .mode_sel(mode_sel),
    .led(led)
);

initial clk = 1'b0;
always #5 clk = ~clk;

task check_led;
    input [7:0] expected;
    begin
        if (led !== expected)
            $fatal(1);
    end
endtask

initial begin
    rst       = 1'b1;
    freq_ctrl = 1'b0; // 先选 cnt_500hz=6
    dir_ctrl  = 1'b1; // 固定左移，本次仿真不切方向
    mode_sel  = 1'b1; // 先显示单灯

    #1;
    check_led(8'b0000_0001); // 复位时只亮 LED0
    @(negedge clk);
    rst = 1'b0;

    // 先完整计数 0..6；tick 到来时 cnt 清零。
    @(posedge dut.tick);
    #1;
    freq_ctrl = 1'b1; // cnt 已回到 0，切换至 cnt_10hz=11，无需复位

    // 再完整计数 0..11，然后切换一次显示模式。
    @(posedge dut.tick);
    #1;
    mode_sel = 1'b0; // 从单灯切换为双灯
    #1;
    check_led(8'b0000_0110);

    @(posedge clk);
    #1;
    check_led(8'b0000_1100);

    $finish;
end

initial begin
    #10000;
    $fatal(1);
end

endmodule
