// 游戏控制：三段式 FSM + 20 秒倒计时 + UART 数字键判定
module whack_a_mole_game #(
    parameter integer CLOCK_HZ = 100_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        mute,
    input  wire        rx_valid,
    input  wire [7:0]  rx_data,
    output wire [31:0] display,
    output wire [7:0]  blank_mask,
    output wire        sound_pwm
);

    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_PLAY = 2'd1;
    localparam [1:0] ST_END  = 2'd2;

    reg [1:0]  current_state;
    reg [1:0]  next_state;
    reg [31:0] second_count;   // 时钟计数器，累计到 1 秒
    reg [5:0]  seconds_left;   // 游戏剩余秒数，初始为 20
    reg [1:0]  end_seconds;    // 结束状态的计时器，用于保持结束状态约 3 秒
    reg [7:0]  score;
    reg [3:0]  mole_position;  // 当前地鼠洞位，范围为 1–8

    wire        second_tick = (second_count >= CLOCK_HZ - 1);   // 1 秒到达时拉高一个时钟周期
    wire [15:0] random_value;   // LFSR 的 16 位伪随机状态，用于产生下一个洞位
    wire        timeout_now = second_tick && (seconds_left <= 6'd1);   //只在秒节拍到达且剩余时间不超过 1 秒时拉高，表示游戏时间到
    wire [2:0]  tone_mode = (current_state == ST_IDLE) ? 3'd1 :
                            (current_state == ST_PLAY) ? 3'd2 :
                            (current_state == ST_END)  ? 3'd5 : 3'd0;   // 选择音效模式：`1` 待机、`2` 游戏中、`5` 结束，其他值静音

    // 收到有效字符，且数字与当前洞位相同时拉高
    wire hit_event = (current_state == ST_PLAY) && !timeout_now && rx_valid &&
                     (rx_data >= 8'h31) && (rx_data <= 8'h38) &&
                     ((rx_data - 8'h30) == {4'b0, mole_position});    // 8'h30` 是 ASCII '0'，减去它可把字符转成数字

    // 收到有效数字字符，但位置与当前洞位不同时拉高
    wire miss_event = (current_state == ST_PLAY) && !timeout_now && rx_valid &&
                      (rx_data >= 8'h31) && (rx_data <= 8'h38) && !hit_event;

    lfsr u_lfsr (
        .clk(clk),
        .rst(rst),
        .advance(hit_event),
        .random_value(random_value)
    );

    whack_tone #(
        .CLOCK_HZ(CLOCK_HZ)
    ) u_whack_tone (
        .clk(clk),
        .rst(rst),
        .mute(mute),
        .mode(tone_mode),
        .hit_event(hit_event),
        .miss_event(miss_event),
        .pwm(sound_pwm)
    );

    game_display u_game_display (
        .state(current_state),
        .score(score),
        .seconds_left(seconds_left),
        .mole_position(mole_position),
        .display(display),
        .blank_mask(blank_mask)
    );

    // 现态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= ST_IDLE;
        else
            current_state <= next_state;
    end

    // 次态组合逻辑
    always @(*) begin
        next_state = current_state;
        case (current_state)
            ST_IDLE: begin
                if (start)
                    next_state = ST_PLAY;
            end
            ST_PLAY: begin
                if (timeout_now)
                    next_state = ST_END;
            end
            ST_END: begin
                if (second_tick && (end_seconds <= 2'd1))
                    next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // 各状态对应的计时、计分和洞位更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            second_count  <= 32'd0;
            seconds_left  <= 6'd20;
            end_seconds   <= 2'd0;
            score         <= 8'd0;
            mole_position <= 4'd1;
        end else begin
            // second_tick计满 1 秒时清零，否则加 1
            if (second_tick)
                second_count <= 32'd0;
            else
                second_count <= second_count + 1'b1;    

            case (current_state)
                ST_IDLE: begin
                    if (start) begin
                        seconds_left  <= 6'd20;
                        end_seconds   <= 2'd0;
                        score         <= 8'd0;
                        mole_position <= 4'd1;
                        second_count  <= 32'd0;
                    end
                end

                ST_PLAY: begin
                    if (hit_event) begin
                        if (score < 8'd99)
                            score <= score + 1'b1;

                    // 将随机数映射到 1..8
                        if (({1'b0, random_value[2:0]} + 1'b1) == mole_position) begin
                            // 跳过当前洞位
                            if (mole_position == 4'd8)
                                mole_position <= 4'd1;
                            else
                                mole_position <= mole_position + 1'b1;
                        end else begin
                            mole_position <= {1'b0, random_value[2:0]} + 1'b1;
                        end
                    end

                    if (timeout_now) begin
                        seconds_left <= 6'd0;
                        end_seconds  <= 2'd3;
                    end else if (second_tick && (seconds_left != 6'd0)) begin
                        seconds_left <= seconds_left - 1'b1;
                    end
                end

                ST_END: begin
                    if (second_tick) begin
                        if (end_seconds != 2'd0)
                            end_seconds <= end_seconds - 1'b1;
                        if (end_seconds <= 2'd1)
                            seconds_left <= 6'd0;
                    end
                end
            endcase
        end
    end

endmodule
