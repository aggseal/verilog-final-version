//   tx_controller  : 按 start 依次发送组别字符、ASCII 加号“+”（8'h2B）、学号；用 tx_done 统计已发送字符
module tx_controller #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter [15:0] EXP_GROUP  = "19",
    parameter [79:0] STUDENT_ID = "2025311563"
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire       tx_done,
    output reg        tx_valid,
    output reg  [7:0] tx_data,
    output reg  [7:0] sent_count
);

localparam integer MESSAGE_LEN = 13; // 2 个组别字符 + 1 个实际发送的“+”字符 + 10 个学号字符；参数变化时同步调整

reg [103:0] message_shift; // 13 字节消息暂存器；发送时从最高字节开始逐字节移出
reg [3:0] byte_index;      // 当前字符序号 0..MESSAGE_LEN-1
reg [1:0] current_state;   // 保存 FSM 当前状态
reg [1:0] next_state;      // 组合逻辑计算的下一状态

wire [4:0] ones_plus_one;
assign ones_plus_one = {1'b0, sent_count[3:0]} + 5'd1;
// 控制状态规划：IDLE 等 start；SEND_REQ 发出一个字节请求；WAIT_DONE 等待发送器完成
localparam [1:0] IDLE = 2'b00;
localparam [1:0] SEND_REQ = 2'b01;
localparam [1:0] WAIT_DONE = 2'b10;


// 第一段：现态寄存器
always @(posedge clk or posedge rst) begin
  if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

//  第二段：次态组合逻辑
always @(*) begin
    next_state = current_state;

    case (current_state)
        IDLE : begin
            if (start)
                next_state = SEND_REQ;  //  start=1 时转 SEND_REQ；忙碌时忽略新的 start
        end
        SEND_REQ : begin
            next_state = WAIT_DONE; //  停留一个周期然后转WAIT_DONE
        end
        //  tx_done=0 时保持等待；tx_done=1 且不是最后一个字符时回 SEND_REQ
        //  tx_done=1 且当前字符为 MESSAGE_LEN-1 时回 IDLE
        WAIT_DONE : begin
            if (tx_done) begin
                if (byte_index < MESSAGE_LEN - 1)
                    next_state = SEND_REQ;
                else 
                    next_state = IDLE;
            end
        end
        default : begin
            next_state=IDLE;
        end
    endcase
end

// 消息、请求和计数的时序逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        message_shift <= 104'd0;
        byte_index <= 4'd0;
        tx_valid <= 1'd0;
        tx_data <= 8'd0;
        sent_count <= 8'd0;
    end
    else begin
        tx_valid <= 1'd0;

        case (current_state)
        // IDLE 接受 start 时装入 {EXP_GROUP, 8'h2B, STUDENT_ID}，byte_index 清零
            IDLE : begin
                if (start) begin
                    message_shift <= {EXP_GROUP, 8'h2B, STUDENT_ID};    //  8'h2B:ASCII“+”字节
                    byte_index <= 4'd0;
                end
            end
            SEND_REQ : begin
                tx_data <= message_shift[103:96];   //存入tx_data
                tx_valid <= 1'd1;
            end
            WAIT_DONE : begin
            // tx_done 到来后才推进
                if (tx_done) begin
                    message_shift <= {message_shift[95:0], 8'd0};
                    byte_index <= byte_index + 4'd1;
                    
                    if (ones_plus_one >= 5'd10) begin
                        sent_count[3:0] <= 4'd0;

                        if (sent_count[7:4] == 4'd9)
                            sent_count[7:4] <= 4'd0; // 99 回到 00
                        else
                            sent_count[7:4] <= sent_count[7:4] + 4'd1;
                        end 
                    else
                        sent_count[3:0] <= ones_plus_one[3:0];
                
                end
            end
            default : begin
                byte_index <= 4'd0;
                tx_data <= 8'd0;
            end
        endcase
    
    end
end

endmodule
