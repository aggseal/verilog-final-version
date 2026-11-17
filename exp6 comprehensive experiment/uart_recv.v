// UART 接收模块：9600 baud、8N1；在数据位中点采样，完整有效帧才更新 data 并脉冲 valid。
module uart_recv #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer BAUD     = 9_600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       din,       // 空闲/停止高，起始位低
    output reg        valid,     // 有效帧完成时单周期脉冲
    output reg  [7:0] data       // 最近一次有效接收字节
);

localparam [1:0] IDLE  = 2'b00;
localparam [1:0] START = 2'b01;
localparam [1:0] DATA  = 2'b10;
localparam [1:0] STOP  = 2'b11;
localparam integer BIT_PERIOD  = CLOCK_HZ / BAUD;
localparam integer HALF_PERIOD = BIT_PERIOD / 2;

//这部分和send的内部信号是一样的
reg [1:0] current_state;
reg [1:0] next_state;
reg [31:0] baud_count;
reg [2:0] bit_index;
reg [7:0] shift_data;   

// 第一段：现态寄存器
always @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// 第二段：次态组合逻辑
always @(*) begin
    next_state = current_state;
    case (current_state)
        IDLE : begin
            if (~din)
                next_state = START;
        end
        START : begin
            if (baud_count == HALF_PERIOD - 1) begin
                if (~din)
                    next_state = DATA; // 起始位中点仍为低，确认起始位
                else
                    next_state = IDLE; // 起始位中点已为高，丢弃毛刺
            end
        end
        DATA : begin
            if ((baud_count == BIT_PERIOD - 1) && (bit_index == 3'd7))
                next_state = STOP;
        end
        STOP : begin
            if (baud_count == BIT_PERIOD - 1)
                next_state = IDLE;
        end
        default : next_state = IDLE;
    endcase
end

// 第三段：计数、采样和输出时序逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_count <= 32'd0;
        bit_index  <= 3'd0;
        shift_data <= 8'd0;
        data       <= 8'd0;
        valid      <= 1'b0;
    end
    else begin
        valid <= 1'b0; // 默认无新字节；有效停止位中点才置 1

        case (current_state)
            IDLE : begin
                baud_count <= 32'd0;
                bit_index  <= 3'd0;
            end

            START : begin
                if (baud_count == HALF_PERIOD - 1)
                    baud_count <= 32'd0;
                else
                    baud_count <= baud_count + 32'd1;
            end

            DATA : begin
                if (baud_count == BIT_PERIOD - 1) begin
                    baud_count <= 32'd0;
                    shift_data[bit_index] <= din;   // bit0 到 bit7 依次采样
                    if (bit_index < 3'd7)
                        bit_index <= bit_index + 3'd1;
                end
                else begin
                    baud_count <= baud_count + 32'd1;
                end
            end

            STOP : begin
                if (baud_count == BIT_PERIOD - 1) begin
                    baud_count <= 32'd0;
                    if (din) begin
                        data  <= shift_data;
                        valid <= 1'b1;
                    end
                end
                else begin
                    baud_count <= baud_count + 32'd1;
                end
            end

            default : begin
                baud_count <= 32'd0;
                bit_index  <= 3'd0;
                shift_data <= 8'd0;
            end
        endcase
    end
end

endmodule