// UART 发送模块：按 CLOCK_HZ 和 BAUD 参数发送一个 8N1 字节。
module uart_send #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer BAUD     = 9_600        
)(
    input  wire       clk,
    input  wire       rst,       // 异步复位，高电平有效
    input  wire       valid,     // IDLE 状态下的单周期发送请求
    input  wire [7:0] data,      // 待发送的 8 位数据
    output reg        dout,      // 空闲电平为高
    output reg        done       // 一帧发送完成脉冲，宽度一个 clk 周期
);

localparam integer BIT_PERIOD = CLOCK_HZ / BAUD;    //计算UART 每个数据位要保持多少个系统时钟周期

localparam [1:0] IDLE  = 2'b00;
localparam [1:0] START = 2'b01;
localparam [1:0] DATA  = 2'b10;
localparam [1:0] STOP  = 2'b11;

reg [1:0] current_state; 
reg [1:0] next_state;    
reg [31:0] baud_count;   // 当前位已经经过的系统时钟周期
reg [2:0] bit_index;     // 正在发送的数据位序号 0..7
reg [7:0] shift_data;    // 暂存发送字节，最低位是下一位要发送的数据

// 描述次态迁移到现态
always @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// 描述状态转移条件判断
always @(*) begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (valid)
                next_state = START;
        end
        START: begin
            if (baud_count == BIT_PERIOD - 1)
                next_state = DATA;
        end
        DATA: begin
            if ((baud_count == BIT_PERIOD - 1) && (bit_index == 3'd7))
                next_state = STOP;
        end
        STOP: begin
            if (baud_count == BIT_PERIOD - 1)
                next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

// 描述输出逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_count <= 32'd0;
        bit_index  <= 3'd0;
        shift_data <= 8'd0;
        dout       <= 1'b1;
        done       <= 1'b0;
    end
    else begin
        done <= 1'b0;
        case (current_state)
            IDLE: begin
                baud_count <= 32'd0;
                bit_index  <= 3'd0;
                dout       <= 1'b1;
                if (valid) begin
                    shift_data <= data;
                    dout       <= 1'b0; // 起始位提前一拍拉低
                end
            end

            START: begin
                dout <= 1'b0;
                if (baud_count == BIT_PERIOD - 1) begin
                    baud_count <= 32'd0;
                    dout       <= shift_data[0]; // 起始位结束，开始发送 data[0]
                    shift_data <= {1'b0, shift_data[7:1]};
                    bit_index  <= 3'd0;
                end
                else begin
                    baud_count <= baud_count + 1'b1;
                end
            end

            DATA: begin
                if (baud_count == BIT_PERIOD - 1) begin
                    baud_count <= 32'd0;
                    if (bit_index == 3'd7) begin
                        dout <= 1'b1; // 第 8 个数据位结束，输出停止位
                    end
                    else begin
                        dout       <= shift_data[0];
                        shift_data <= {1'b0, shift_data[7:1]};
                        bit_index  <= bit_index + 1'b1;
                    end
                end
                else begin
                    baud_count <= baud_count + 1'b1;
                end
            end

            STOP: begin
                dout <= 1'b1;
                if (baud_count == BIT_PERIOD - 1) begin
                    baud_count <= 32'd0;
                    done       <= 1'b1; // 整帧完成，只脉冲一个时钟周期
                end
                else begin
                    baud_count <= baud_count + 1'b1;
                end
            end

            default: begin
                baud_count <= 32'd0;
                bit_index  <= 3'd0;
                dout       <= 1'b1;
            end
        endcase
    end
end

endmodule