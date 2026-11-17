//   led_ctrl_unit  : 根据 display 和 blank_mask 扫描数码管；blank_mask 对应位置为 1 时关闭该位全部段
module led_ctrl_unit #(
    parameter integer SCAN_DIV = 100_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display,    // 每个 nibble 对应 DK0-DK7 的显示数值
    input  wire [7:0]  blank_mask, // blank_mask[i]=1 时 DK i 完全熄灭
    output reg  [7:0]  led_en,     // 8 位数码管位选信号，一次选择一位
    output reg  [7:0]  led_cx0,    //段选输出，cx0 对应 DK7-DK4
    output reg  [7:0]  led_cx1     //DK3-DK0
);

reg [2:0]  index;       // 当前扫描的位号，0..7 分别对应 DK0..DK7
reg [16:0] count;       // 在当前位停留期间的时钟计数值
wire       scantick;    // 扫描节拍，只在 count 达到阈值时为 1，用来触发换位
reg [3:0]  digit;       // 从 display 选择出的当前位数值
reg        digit_blank; // 当前扫描位对应的空白标志
reg [7:0]  seg_code;    //digit 对应的七段数码管段码

assign scantick = (count == SCAN_DIV - 1);    // 后续时序逻辑据此清零 count 并切换 index


// 扫描计数器和位号更新 
always @(posedge clk or posedge rst) begin
    if (rst) begin
        index <= 3'd0;
        count <= 17'd0;
    end
    else if (scantick) begin
        count <= 17'd0;     // 到达扫描节拍后清零
        if (index == 3'd7)
            index <= 3'd0;  // 循环扫描 DK0-DK7
        else 
            index <= index + 3'd1;
    end
    else
        count <= count + 17'd1;
end

// 当前显示位数据选择 
always @(*) begin
    digit_blank = blank_mask[index]; // 与当前 index 对齐，取得该位是否留空
    case (index)
        3'd0 : digit = display[3:0];
        3'd1 : digit = display[7:4];
        3'd2 : digit = display[11:8];
        3'd3 : digit = display[15:12];
        3'd4 : digit = display[19:16];
        3'd5 : digit = display[23:20];
        3'd6 : digit = display[27:24];
        3'd7 : digit = display[31:28];
        default : digit = 4'd0;
    endcase
end

// 空白优先控制及十六进制数值到段码译码
always @(*) begin
    if (digit_blank) begin
        seg_code = 8'h00; // 当前位 blank_mask[index] 为 1 时输出全灭段码；否则按 digit 查 0-F 段码表
    end
    else begin
    case (digit)
        4'h0 : seg_code = 8'hFC;     // "1111_1110"
        4'h1 : seg_code = 8'h60;     
        4'h2 : seg_code = 8'hDA;
        4'h3 : seg_code = 8'hF2;
        4'h4 : seg_code = 8'h66;
        4'h5 : seg_code = 8'hB6;
        4'h6 : seg_code = 8'hBE;
        4'h7 : seg_code = 8'hE0;
        4'h8 : seg_code = 8'hFE;
        4'h9 : seg_code = 8'hF6;
        4'hA : seg_code = 8'hEE;
        4'hB : seg_code = 8'h3E;
        4'hC : seg_code = 8'h9C;
        4'hD : seg_code = 8'h7A;
        4'hE : seg_code = 8'h9E;
        4'hF : seg_code = 8'h8E;
        default : seg_code = 8'h00;
    endcase
    end
end

// 当前位的位选译码：按 exp4 的 EGO1 约定，高电平 one-hot 选中一位。
always @(*) begin
    case (index)
        3'd0: led_en = 8'b0000_0001; // DK0，右端
        3'd1: led_en = 8'b0000_0010;
        3'd2: led_en = 8'b0000_0100;
        3'd3: led_en = 8'b0000_1000;
        3'd4: led_en = 8'b0001_0000;
        3'd5: led_en = 8'b0010_0000;
        3'd6: led_en = 8'b0100_0000;
        3'd7: led_en = 8'b1000_0000; // DK7，左端
        default: led_en = 8'b0000_0000;
    endcase
end
// 段码输出到对应数码管组 
always @(*) begin
    led_cx0 = 8'd0;
    led_cx1 = 8'd0;    // 避免未选中的组残留旧段码
    
    if (index[2] == 1)  // 1xx即大于3，高位
        led_cx0 = seg_code;
    else 
        led_cx1 = seg_code;
end

endmodule