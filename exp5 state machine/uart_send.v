module uart_send#(
    parameter CLOCK_HZ = 100_000_000, // 输入时钟频率，单位 Hz
    parameter BAUD = 9_600            // UART 波特率，单位 bit/s
)(
    input        clk,       // 系统时钟
    input        rst,       // 异步复位，高电平有效
    input        valid,     // 在 IDLE 状态请求发送 data；应为一个时钟周期
    input  [7:0] data,      // 待发送的 8 位 ASCII/二进制数据
    output reg   dout       // UART TX 输出；空闲、停止位为高电平
);

// UART 一帧格式：低电平起始位 + 8 个数据位（低位先发）+ 高电平停止位。
localparam integer BIT_PERIOD = CLOCK_HZ / BAUD;

// IDLE 等待请求；START 发送起始位；DATA 发送 8 个数据位；STOP 发送停止位
localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP = 2'b11;

reg [31:0] baud_count;   // 当前 UART 位内已计过的系统时钟数
reg [2:0] bit_index;     // 当前数据位序号：0 到 7，先发送 data[0]
reg [7:0] shift_data;    // 锁存 data 后逐位右移，最低位是下一位要发送的数据
reg [1:0] current_state; // 状态寄存器保存的当前状态
reg [1:0] next_state;    // 组合逻辑计算的下一状态

// 现态寄存器。只在时钟沿更新状态；复位时回到 IDLE
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
    end
    else 
        current_state <= next_state;
end

always @(*) begin
    next_state = current_state; // 默认保持，保证所有条件下都有确定的次态
    case (current_state) 
        IDLE : begin
            if (valid)
                next_state = START; // 收到一次请求后开始发送
        end
        START : begin
            if (baud_count == BIT_PERIOD - 1)
                next_state = DATA;  // 起始位保持满一个位宽后，进入数据位
        end
        DATA : begin
            if ((baud_count == BIT_PERIOD - 1) && (bit_index == 3'd7))
                next_state = STOP;  // 第 7 位保持满一个位宽后，进入停止位
        end
        STOP : begin
            if (baud_count == BIT_PERIOD - 1 )
                next_state = IDLE;  // 停止位保持满一个位宽后，回到空闲
        end
        default : begin
            next_state = IDLE;
        end
    endcase
end

// 复位时线路保持空闲高电平，并清除本帧的计数和暂存数据。
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_count <= 32'b0;
        bit_index <= 3'b0;
        shift_data <= 8'b0;
        dout <= 1'b1;       // 复位期间 UART TX 处于空闲电平
    end
    else begin
        case (current_state)
            IDLE : begin
                baud_count <= 32'b0;
                bit_index <= 3'b0;
                dout <= 1'b1;

                if (valid) begin
                    shift_data <= data; // 请求时锁存整字节，后续不受 data 输入变化影响
                    dout <= 1'b0;       // 输出低电平起始位
                end
            end
            START : begin
                dout <= 1'b0;  // 起始位保持低电平，baud_count 同时统计位宽
                if (baud_count == BIT_PERIOD-1) begin
                    baud_count <= 32'b0;
                    dout <= shift_data[0];                // 起始位结束，输出第 0 位数据
                    shift_data <= {1'b0, shift_data[7:1]}; // 右移，让下一数据位来到最低位
                    bit_index <= 3'd0;                     // 已开始输出第 0 位
                end
                else begin
                    baud_count <= baud_count + 32'b1;
                end
            end
            DATA : begin
                if (baud_count == BIT_PERIOD-1) begin
                    baud_count <= 32'b0;
                    if (bit_index == 3'd7)
                        dout <= 1'b1; // 第 7 位已保持满一个位宽，拉高输出停止位
                    else begin
                        dout <= shift_data[0]; // 当前数据位结束，输出下一位
                        shift_data <= {1'b0, shift_data[7:1]};
                        bit_index <= bit_index + 3'b1; // 数据位序号加一
                    end 
                end
                else 
                    baud_count <= baud_count + 32'b1; // 本位尚未计满，继续计数
            end
            STOP : begin
                dout <= 1'b1;   // 停止位为高电平
                if (baud_count == BIT_PERIOD-1)
                    baud_count <= 32'b0;    // 停止位计满，清零计数器
                else 
                    baud_count <= baud_count + 32'b1;
            end
            default : begin
                dout <= 1'b1;
                baud_count <= 32'b0;
                bit_index <= 3'b0;
            end
        endcase
    end
 end

endmodule
