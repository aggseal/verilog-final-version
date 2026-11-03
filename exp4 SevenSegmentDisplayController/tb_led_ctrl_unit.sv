`timescale 1ns/1ps

module tb_led_ctrl_unit;
    reg         clk;
    reg         rst;
    reg  [31:0]  display;
    wire [7:0]   led_en;
    wire [7:0]   led_cx0;
    wire [7:0]   led_cx1;

    integer errors;
    integer i;
    localparam integer SCAN_DIV = 10;

    led_ctrl_unit #(.SCAN_DIV(SCAN_DIV)) dut (
        .clk(clk),
        .rst(rst),
        .display(display),
        .led_en(led_en),
        .led_cx0(led_cx0),
        .led_cx1(led_cx1)
    );

    always #5 clk = ~clk;

    function [7:0] seg_for;
        input [3:0] value;
        begin
            case (value)
                4'h0: seg_for = 8'hFC;
                4'h1: seg_for = 8'h60;
                4'h2: seg_for = 8'hDA;
                4'h3: seg_for = 8'hF2;
                4'h4: seg_for = 8'h66;
                4'h5: seg_for = 8'hB6;
                4'h6: seg_for = 8'hBE;
                4'h7: seg_for = 8'hE0;
                4'h8: seg_for = 8'hFE;
                4'h9: seg_for = 8'hF6;
                4'hA: seg_for = 8'hEE;
                4'hB: seg_for = 8'h3E;
                4'hC: seg_for = 8'h9C;
                4'hD: seg_for = 8'h7A;
                4'hE: seg_for = 8'h9E;
                4'hF: seg_for = 8'h8E;
                default: seg_for = 8'h00;
            endcase
        end
    endfunction

    task check_digit;
        input integer idx;
        reg [3:0] selected_digit;
        reg [7:0] expected_seg;
        reg [7:0] expected_en;
        begin
            case (idx)
                0: selected_digit = display[3:0];
                1: selected_digit = display[7:4];
                2: selected_digit = display[11:8];
                3: selected_digit = display[15:12];
                4: selected_digit = display[19:16];
                5: selected_digit = display[23:20];
                6: selected_digit = display[27:24];
                7: selected_digit = display[31:28];
                default: selected_digit = 4'h0;
            endcase
            expected_seg = seg_for(selected_digit);
            expected_en = 8'b0000_0001 << idx;

            if (led_en !== expected_en) begin
                $display("FAIL index=%0d: led_en=%b expected=%b", idx, led_en, expected_en);
                errors = errors + 1;
            end


            if (idx < 4) begin
                if ((led_cx0 !== 8'h00) || (led_cx1 !== expected_seg)) begin
                    $display("FAIL index=%0d digit=%h: cx0=%h cx1=%h expected right-bank=%h",
                             idx, selected_digit, led_cx0, led_cx1, expected_seg);
                    errors = errors + 1;
                end
            end else begin
                if ((led_cx0 !== expected_seg) || (led_cx1 !== 8'h00)) begin
                    $display("FAIL index=%0d digit=%h: cx0=%h cx1=%h expected left-bank=%h",
                             idx, selected_digit, led_cx0, led_cx1, expected_seg);
                    errors = errors + 1;
                end
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        display = 32'h25311563;
        errors = 0;
        $dumpfile("tb_led_ctrl_unit.vcd");
        $dumpvars(0, tb_led_ctrl_unit);

        #12 rst = 1'b0;
        #1;
        for (i = 0; i < 24; i = i + 1) begin
            if (i == 8)  display = 32'h76543210;
            if (i == 16) display = 32'hFEDCBA98;
            #1;
            check_digit(i % 8);
            repeat (SCAN_DIV) @(posedge clk);
            #1;
        end

        if (errors == 0)
            $display("PASS: led_ctrl_unit scan and segment checks completed.");
        else
            $display("FAIL: led_ctrl_unit reported %0d errors.", errors);
        $finish;
    end
endmodule