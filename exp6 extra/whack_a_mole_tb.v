`timescale 1ns / 1ps

module whack_a_mole_tb;
    localparam integer CLOCK_HZ = 1000;
    localparam integer BAUD = 100;
    localparam integer BIT_CYCLES = CLOCK_HZ / BAUD;

    reg clk;
    reg rst;
    reg key_s2;
    reg uart_rx;
    reg mute_sw;

    wire sound_pwm;
    wire [7:0] led_en;
    wire [7:0] led_cx0;
    wire [7:0] led_cx1;

    integer mole_before;

    top #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD(BAUD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .key_s2(key_s2),
        .uart_rx(uart_rx),
        .mute_sw(mute_sw),
        .sound_pwm(sound_pwm),
        .led_en(led_en),
        .led_cx0(led_cx0),
        .led_cx1(led_cx1)
    );

    always #5 clk = ~clk;

    task press_start;
        begin
            @(negedge clk);
            key_s2 = 1'b1;
            repeat (15) @(negedge clk);
            key_s2 = 1'b0;
            repeat (5) @(negedge clk);
        end
    endtask

    task send_uart_byte;
        input [7:0] data_byte;
        integer i;
        begin
            @(negedge clk);
            uart_rx = 1'b0;
            repeat (BIT_CYCLES) @(negedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data_byte[i];
                repeat (BIT_CYCLES) @(negedge clk);
            end
            uart_rx = 1'b1;
            repeat (2 * BIT_CYCLES) @(negedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        key_s2 = 1'b0;
        uart_rx = 1'b1;
        mute_sw = 1'b0;

        repeat (5) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);

        if (dut.u_whack_a_mole_game.current_state !== 2'd0) begin
            $display("FAIL: 复位后没有进入待机状态");
            $finish;
        end

        press_start();
        if (dut.u_whack_a_mole_game.current_state !== 2'd1) begin
            $display("FAIL: 按下 S2 后没有开始游戏");
            $finish;
        end

        mole_before = dut.u_whack_a_mole_game.mole_position;
        send_uart_byte(8'h32); // 初始洞位为 1，发送字符 '2' 应判错。
        repeat (2) @(negedge clk);
        if (dut.u_whack_a_mole_game.score !== 8'd0 ||
            dut.u_whack_a_mole_game.mole_position !== mole_before) begin
            $display("FAIL: 错误输入改变了分数或洞位");
            $finish;
        end

        send_uart_byte(8'h31); // 发送字符 '1' 命中初始洞位。
        repeat (2) @(negedge clk);
        if (dut.u_whack_a_mole_game.score !== 8'd1) begin
            $display("FAIL: 命中后分数没有增加");
            $finish;
        end
        if (dut.u_whack_a_mole_game.mole_position === mole_before) begin
            $display("FAIL: 命中后洞位没有改变");
            $finish;
        end

        wait (dut.u_whack_a_mole_game.current_state == 2'd2);
        if (dut.u_whack_a_mole_game.seconds_left !== 0) begin
            $display("FAIL: 游戏结束时倒计时不为 0");
            $finish;
        end

        repeat (CLOCK_HZ * 3 + 5) @(negedge clk);
        if (dut.u_whack_a_mole_game.current_state !== 2'd0) begin
            $display("FAIL: 结束阶段后没有返回待机状态");
            $finish;
        end

        $display("PASS: 复位、开始、命中/错误判定、20 秒结束及返回待机均通过");
        $finish;
    end
endmodule
