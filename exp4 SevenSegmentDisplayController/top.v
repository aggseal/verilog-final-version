module top (
    input  wire       clk,
    input  wire       rst,
    input  wire       key_s2,
    input  wire       key_s3,
    input  wire       sw0,
    output wire [7:0] led_en,
    output wire [7:0] led_cx0,
    output wire [7:0] led_cx1
);

// 声明模块间信号，并例化 debounce、edge_detect、led_ctrl_unit
// 按键消抖后的电平和按下脉冲
wire s2_clean;
wire s2_press;

wire s3_clean;
wire s3_raw_press;
wire s3_clean_press;

reg [7:0] s3_raw_bcd;
reg [7:0] s3_clean_bcd; 

reg run; // S2 按下后切换运行/暂停状态

reg  [23:0] tick_count;
wire        tick_0p1s;
reg  [7:0]  timer_bcd; // 0.1 秒节拍与 00～20 的 BCD 计数

reg [31:0] display; // 送给数码管控制器的八个十六进制数字

// S2：消抖后检测按下沿
debounce #(
    .STABLE_CYCLES(1_000_000)
)u_debounce_s2(
    .clk(clk),
    .rst(rst),
    .key_in(key_s2),
    .key_clean(s2_clean)
);

edge_detect u_edge_s2(
    .clk(clk),
    .rst(rst),
    .signal_in(s2_clean),
    .rise_pulse(s2_press)
);

// S3：消抖支路
debounce #(
    .STABLE_CYCLES(1_000_000)
)u_debounce_s3(
    .clk(clk),
    .rst(rst),
    .key_in(key_s3),
    .key_clean(s3_clean)
);

// S3：未消抖支路
edge_detect u_edge_s3_raw(
    .clk(clk),
    .rst(rst),
    .signal_in(key_s3),
    .rise_pulse(s3_raw_press)
);

// S3：消抖后检测按下沿
edge_detect u_edge_s3_clean(
    .clk(clk),
    .rst(rst),
    .signal_in(s3_clean),
    .rise_pulse(s3_clean_press)
);

led_ctrl_unit u_led_ctrl_unit(
    .clk(clk),
    .rst(rst),
    .display(display),
    .led_en(led_en),
    .led_cx0(led_cx0),
    .led_cx1(led_cx1)
);

// S2 每按下一次，切换一次运行/暂停状态
always @(posedge clk or posedge rst) begin
    if (rst)
        run <= 1'b1;
    else if (s2_press)
        run <= ~run;
end

// 未消抖的 S3 计数：00～99
always @(posedge clk or posedge rst) begin
    if (rst)
        s3_raw_bcd <= 8'b0;
    else if (s3_raw_press) begin
        if (s3_raw_bcd[3:0] == 4'd9) begin
            s3_raw_bcd[3:0] <= 4'd0;
            
            if (s3_raw_bcd[7:4] == 4'd9)
                s3_raw_bcd[7:4] <= 4'd0;
            else
                s3_raw_bcd[7:4] <= s3_raw_bcd[7:4] + 1'b1;
        end
        else
            s3_raw_bcd[3:0] <= s3_raw_bcd[3:0] + 1'b1;
    end
end

// 消抖后的 S3 计数：00～99
always @(posedge clk or posedge rst) begin
    if (rst)
        s3_clean_bcd <= 8'b0;
    else if (s3_clean_press) begin
        if (s3_clean_bcd[3:0] == 4'd9) begin
            s3_clean_bcd[3:0] <= 4'd0;
            
            if (s3_clean_bcd[7:4] == 4'd9)
                s3_clean_bcd[7:4] <= 4'd0;
            else
                s3_clean_bcd[7:4] <= s3_clean_bcd[7:4] + 1'b1;
        end
        else
            s3_clean_bcd[3:0] <= s3_clean_bcd[3:0] + 1'b1;
    end
end

// 100 MHz 时钟计数 10,000,000 次，产生 0.1 秒节拍
assign tick_0p1s = (tick_count == 24'd9_999_999);

always @(posedge clk or posedge rst) begin
    if (rst)
        tick_count <= 24'd0;
    else if (tick_0p1s)
        tick_count <= 24'd0;
    else
        tick_count <= tick_count + 24'd1;
end

// 运行时每 0.1 秒加一，计数范围为 00～20
always @(posedge clk or posedge rst) begin
    if (rst)
        timer_bcd <= 8'h00;
    else if (run && tick_0p1s) begin
        if (timer_bcd == 8'h20)
            timer_bcd <= 8'h00;
        else if (timer_bcd[3:0] == 4'd9) begin
            timer_bcd[3:0] <= 4'd0;
            timer_bcd[7:4] <= timer_bcd[7:4] + 1'b1;
        end
        else
            timer_bcd[3:0] <= timer_bcd[3:0] + 1'b1;
    end
end

// SW0=1 显示学号；SW0=0 显示实验计数内容
always @(*) begin
    if (sw0)
        display = 32'h2531_1563;
    else begin
        display[31:24] = 8'h63;
        display[23:16] = s3_raw_bcd;
        display[15:8]  = s3_clean_bcd;
        display[7:0]   = timer_bcd;
    end
end

endmodule