module top #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter [79:0] STUDENT_ID = "2025311563" 
)(
    input  wire clk,      
    input  wire rst,      
    output wire uart_tx   
);

reg [119:0] message_shift;
wire [7:0] data;  // 当前要交给 uart_send 的一个字符
wire valid;       // 发送请求；为 1 时 uart_send 在时钟沿锁存 data

localparam SEND_BYTE  = 2'b00; // 发出一个字符请求
localparam BYTE_GAP   = 2'b01; // 一条消息内相邻字符的间隔
localparam STRING_GAP = 2'b10; // 两整条消息之间的间隔
reg [1:0] current_state; // 当前所处状态
reg [1:0] next_state;    // 次态

reg [3:0] byte_index;       // 用于判断是否已请求到最后一个字符
reg [31:0] interval_count;  // 等待时钟数；在 BYTE_GAP 和 STRING_GAP 中递增

// 把实验要求的时间换算为时钟周期数，计数器才能用 clk 实际计时
localparam integer MESSAGE_LEN = 15;                     
localparam integer BYTE_INTERVAL_CYCLES = CLOCK_HZ / 100; // 10 ms 对应的时钟数
localparam integer STRING_INTERVAL_CYCLES = CLOCK_HZ / 4; // 250 ms，对应整串之间的等待

// 实例化 UART 发送模块。顶层把时钟、复位、请求和当前字符送入子模块
uart_send #(
    .CLOCK_HZ(CLOCK_HZ),
    .BAUD(9_600)
) u_uart_send (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .data(data),
    .dout(uart_tx)
);

// 取移位寄存器最左侧的 8 位作为当前字符。复位装入消息后这里是 'h'
// 每发送一个字符后左移 8 位，下一个字符就会来到这里
assign data = message_shift[119:112];

// rst 拉高时直接回到 SEND_BYTE，使复位释放后从消息首字符开始
always @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= SEND_BYTE;
    else
        current_state <= next_state;
end

// 默认保持 current_state，表示条件尚未满足时继续等待；满足条件后再改写 next_state。
always @(*) begin
    next_state = current_state;
    case (current_state)
        SEND_BYTE: begin
            // 发出了一个字符请求，若它是最后一个字符，整串结束；否则转去等待下一字符
            if (byte_index == MESSAGE_LEN - 1) 
                next_state = STRING_GAP;
            else
                next_state = BYTE_GAP; 
        end 
        BYTE_GAP: begin
            // 提前两拍离开等待态：一拍切换状态，下一拍 uart_send 才采样 valid
            if (interval_count == BYTE_INTERVAL_CYCLES - 2)
                next_state = SEND_BYTE;
        end
        STRING_GAP: begin
            // 两条消息之间等待更久；计满后回到 SEND_BYTE，开始下一轮
            if (interval_count == STRING_INTERVAL_CYCLES - 1)
                next_state = SEND_BYTE;
        end
        default: next_state = SEND_BYTE;
    endcase
end

// valid 直接由状态译码：SEND_BYTE 时为 1，其余等待状态为 0
// SEND_BYTE 只停留一个时钟周期，所以 valid 是单周期脉冲，避免重复请求同一字符
assign valid = (current_state == SEND_BYTE);    

// 复位时初始化这些寄存器；正常工作时根据 current_state 更新它们
always @(posedge clk or posedge rst) begin
    if (rst) begin
        byte_index <= 4'd0;
        interval_count <= 32'd0;
        message_shift <= {"hitsz", STUDENT_ID};
    end else begin
        case (current_state)
            SEND_BYTE: begin
                // SEND_BYTE 这一拍提出一次请求，因此清零计数器，为后续等待重新计时
                interval_count <= 32'd0;
                if (byte_index == MESSAGE_LEN - 1) begin
                    byte_index <= 4'b0;
                    message_shift <= {"hitsz", STUDENT_ID};
                end else begin
                        byte_index <= byte_index + 4'd1;
                        message_shift <= {message_shift[111:0], 8'h00};
                end
            end
            BYTE_GAP: begin
                // 临界是字符间隔阈值时
                if (interval_count >= BYTE_INTERVAL_CYCLES - 2)
                    interval_count <= 32'd0;
                else 
                    interval_count <= interval_count + 32'd1;
            end
            STRING_GAP: begin
                if (interval_count >= STRING_INTERVAL_CYCLES - 1)
                    interval_count <= 32'd0;
                else 
                    interval_count <= interval_count + 32'd1;
            end
            default: begin
                // 清计数和字符序号，并恢复消息首字符
                byte_index <= 4'd0;
                interval_count <= 32'd0;
                message_shift <= {"hitsz", STUDENT_ID};
            end
        endcase
    end
end

endmodule
