// UART 接收显示数据整理模块，ASCII 0-F 映射为数码管字形，保留最近 6 个有效字符；DK0-DK1 显示发送字符数
module uart_display (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_valid,
    input  wire [7:0] rx_data,
    input  wire [7:0] sent_count,  // 两位 BCD：高 nibble 十位，低 nibble 个位
    output reg  [31:0] display,     // display[3:0]=DK0
    output reg  [7:0]  blank_mask  // bit i=1 表示 DK i 完全熄灭
);

reg [3:0] char0, char1, char2, char3, char4, char5;
reg [5:0] char_valid;              // bit0 对应 char0/DK2，bit5 对应 char5/DK7
reg [3:0] count_tens, count_ones;
reg [3:0] mapped_char;  // 保存当前接收字节转换后的 4 位字符值
reg       mapped_valid; // 表示当前接收字节是否是支持显示的字符

// ASCII 码转为数码管显示用的十六进制 nibble，rx_data 收到的是 ASCII 编码
always @(*) begin
    mapped_char  = 4'h0;
    mapped_valid = 1'b1;
    case (rx_data)
        // 0~9
        8'h30 : mapped_char = 4'h0; 
        8'h31 : mapped_char = 4'h1; 
        8'h32 : mapped_char = 4'h2; 
        8'h33 : mapped_char = 4'h3; 
        8'h34 : mapped_char = 4'h4; 
        8'h35 : mapped_char = 4'h5;
        8'h36 : mapped_char = 4'h6;
        8'h37 : mapped_char = 4'h7; 
        8'h38 : mapped_char = 4'h8; 
        8'h39 : mapped_char = 4'h9; 
        
        // 大和小写 A–F 都映射为同一个 4 位值
        8'h41, 8'h61 : mapped_char = 4'hA; 
        8'h42, 8'h62 : mapped_char = 4'hB; 
        8'h43, 8'h63 : mapped_char = 4'hC; 
        8'h44, 8'h64 : mapped_char = 4'hD; 
        8'h45, 8'h65 : mapped_char = 4'hE;
        8'h46, 8'h66 : mapped_char = 4'hF; 
        default : begin
            mapped_char  = 4'h0;
            mapped_valid = 1'b0;
        end
    endcase
end

// 接收字符滚动缓存：新字符进入 char0/DK2，已有字符依次向较高位移动
// 非法字符或 rx_valid=0 时不改变缓存；多于 6 个字符时最旧字符自然移出
always @(posedge clk or posedge rst) begin
    if (rst) begin
        char0      <= 4'h0;
        char1      <= 4'h0;
        char2      <= 4'h0;
        char3      <= 4'h0;
        char4      <= 4'h0;
        char5      <= 4'h0;
        char_valid <= 6'b0;
    end
    else if (rx_valid && mapped_valid) begin
        char0      <= mapped_char;
        char1      <= char0;
        char2      <= char1;
        char3      <= char2;
        char4      <= char3;
        char5      <= char4;
        char_valid <= {char_valid[4:0], 1'b1};
    end
end

// 显示数据和空白掩码组合逻辑：DK0 个位，DK1 显示十位；char0..char5 分别显示在 DK2..DK7
// 未填充的字符槽通过 blank_mask 熄灭
always @(*) begin
    count_ones = sent_count[3:0];
    count_tens = sent_count[7:4];

    display = 32'd0;
    display[3:0]   = count_ones; // DK0：发送计数个位
    display[7:4]   = count_tens; // DK1：发送计数十位
    display[11:8]  = char0;      // DK2：最新字符
    display[15:12] = char1;
    display[19:16] = char2;
    display[23:20] = char3;
    display[27:24] = char4;
    display[31:28] = char5;      // DK7：第 6 新的字符

    blank_mask = 8'b0;
    blank_mask[1:0] = 2'b00;     // 两位发送计数始终显示
    blank_mask[2] = ~char_valid[0];
    blank_mask[3] = ~char_valid[1];
    blank_mask[4] = ~char_valid[2];
    blank_mask[5] = ~char_valid[3];
    blank_mask[6] = ~char_valid[4];
    blank_mask[7] = ~char_valid[5];
end

endmodule