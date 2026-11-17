// mode: 0 静音，1 待机，2 游戏，5 游戏结束；LD1_0 用可见闪烁频率区分效果
module whack_tone #(
    parameter integer CLOCK_HZ = 100_000_000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       mute,
    input  wire [2:0] mode,
    input  wire       hit_event,
    input  wire       miss_event,
    output reg        pwm
);
    // 背景节奏每半秒切换一次；命中或错误提示持续四分之一秒
    localparam integer MUSIC_TICK = CLOCK_HZ / 2;
    localparam integer EVENT_TICK = CLOCK_HZ / 4;

    reg [31:0] music_count; // 累计时钟周期，满半秒后清零
    reg [3:0]  music_step;  // 每次 music_count 计满就加 1，再用它选择当前闪烁频率
    reg [31:0] event_count; // 持续计时器，逐周期递减
    reg        event_is_hit;// `1` 表示命中，`0` 表示错误，用来选择对应的闪烁频率

    reg [31:0] tone_count;  // 当前要输出的闪烁频率
    reg [15:0] tone_hz;     // `pwm` 每次翻转前需经过的时钟周期数
    reg [31:0] half_period; // 累计时钟周期；达到 half_period 后清零并翻转 pwm

    // 产生 LED 的背景闪烁节奏
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            music_count <= 0;
            music_step <= 0;
            event_count <= 0;
            event_is_hit <= 0;
        end else begin
            if (music_count >= MUSIC_TICK - 1) begin
                music_count <= 0;
                music_step <= music_step + 1'b1;
            end 
            else begin
                music_count <= music_count + 1'b1;
            end

            // 同时发生时优先命中提示；没有新事件时，事件计时逐拍递减。
            if (hit_event) begin
                event_count <= EVENT_TICK;
                event_is_hit <= 1'b1;
            end 
            else if (miss_event) begin
                event_count <= EVENT_TICK;
                event_is_hit <= 1'b0;
            end 
            else if (event_count != 0) begin
                event_count <= event_count - 1'b1;
            end
        end
    end

    // 组合选择当前频率：短暂命中/错误提示优先于待机、游戏或结束背景节奏
    always @(*) begin
        tone_hz = 0;
        // 命中用 8 Hz，错误用 1 Hz
        if (event_count != 0) begin
            tone_hz = event_is_hit ? 8 : 1;
        end else begin
            case (mode)
                3'd1: begin
                    case (music_step[1:0])
                        2'd0: tone_hz = 1;
                        2'd1: tone_hz = 2;
                        2'd2: tone_hz = 3;
                        default: tone_hz = 2;
                    endcase
                end
                3'd2: begin
                    case (music_step[1:0])
                        2'd0: tone_hz = 4;
                        2'd1: tone_hz = 5;
                        2'd2: tone_hz = 6;
                        default: tone_hz = 5;
                    endcase
                end
                3'd5: begin
                    case (music_step[3:1])
                        3'd0, 3'd1: tone_hz = 6;
                        3'd2, 3'd3: tone_hz = 4;
                        3'd4, 3'd5: tone_hz = 2;
                        default: tone_hz = 0;
                    endcase
                end
                default: begin
                    tone_hz = 0;
                end
            endcase
        end

        // 方波每半个周期翻转一次，所以计数阈值为时钟频率除以两倍闪烁频率。
        if (tone_hz == 0)
            half_period = 0;
        else
            half_period = CLOCK_HZ / (2 * tone_hz);
    end

    // 静音或无音效时输出低电平；达到半周期阈值后翻转 pwm，驱动 LD1_0 闪烁。
    always @(posedge clk or posedge rst) begin
        if (rst || mute || (half_period == 0)) begin
            tone_count <= 0;
            pwm <= 1'b0;
        end else if (tone_count >= half_period - 1) begin
            tone_count <= 0;
            pwm <= ~pwm;
        end else begin
            tone_count <= tone_count + 1'b1;
        end
    end
endmodule
