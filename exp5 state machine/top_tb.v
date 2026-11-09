`timescale 1ns/1ps
module top_tb;
    localparam integer SIM_CLOCK_HZ = 10_500_000;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_HZ;
    localparam integer BIT_PERIOD_CYCLES = SIM_CLOCK_HZ / 9_600;
    localparam real BIT_PERIOD_NS = BIT_PERIOD_CYCLES * CLK_PERIOD_NS;
    localparam real MAX_CHAR_INTERVAL_NS = 10_000_000.0;
    localparam real MIN_STRING_INTERVAL_NS = 200_000_000.0;

    reg clk;
    reg rst;
    wire uart_tx;
    reg [119:0] expected_message;
    reg [7:0] received_byte;
    reg [7:0] expected_byte;
    realtime previous_start;
    realtime current_start;
    integer char_no;

    top #(
        .CLOCK_HZ(SIM_CLOCK_HZ),
        .STUDENT_ID("2025311563")
    ) dut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx)
    );

    always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

    task receive_byte;
        output reg [7:0] value;
        output realtime start_time;
        integer bit_no;
        begin
            @(negedge uart_tx);
            start_time = $realtime;
            // 起始边沿后 1.5 位时间位于 data[0] 中心
            #(BIT_PERIOD_NS * 1.5);
            for (bit_no = 0; bit_no < 8; bit_no = bit_no + 1) begin
                value[bit_no] = uart_tx;
                #(BIT_PERIOD_NS);
            end
            if (uart_tx !== 1'b1) begin
                $display("FAIL: stop bit is low at %0t ns", $realtime);
                $finish;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        expected_message = {"hitsz", "2025311563"};
        previous_start = 0.0;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        for (char_no = 0; char_no < 15; char_no = char_no + 1) begin
            receive_byte(received_byte, current_start);
            expected_byte = expected_message[119:112];
            if (received_byte !== expected_byte) begin
                $display("FAIL: char %0d expected 0x%02h, got 0x%02h",
                         char_no, expected_byte, received_byte);
                $finish;
            end
            if (char_no > 0 &&
                (current_start - previous_start) > MAX_CHAR_INTERVAL_NS) begin
                $display("FAIL: character request interval exceeds 10 ms.");
                $finish;
            end
            previous_start = current_start;
            expected_message = {expected_message[111:0], 8'h00};
        end

        // 检查下一轮是否从 h 开始，且整串间隔不少于 200 ms
        receive_byte(received_byte, current_start);
        if (received_byte !== 8'h68) begin
            $display("FAIL: next string should restart with ASCII h, got 0x%02h", received_byte);
            $finish;
        end
        if ((current_start - previous_start) < MIN_STRING_INTERVAL_NS) begin
            $display("FAIL: string interval is shorter than 200 ms.");
            $finish;
        end

        $display("PASS: top sent the full string in order and restarted after the required gap.");
        $finish;
    end

    initial begin
        #450_000_000; // 450 ms 仿真超时
        $display("FAIL: top test timed out.");
        $finish;
    end
endmodule
