module led_ctrl_unit #(
    parameter integer SCAN_DIV = 100_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display,
    output reg  [7:0]  led_en,
    output reg  [7:0]  led_cx0,
    output reg  [7:0]  led_cx1
);

reg [2:0]  index;
reg [16:0] count;
wire       scantick;
reg [3:0]  digit;
reg [7:0]  seg_code;

// count到达SCANDIV-1时，scantick在一个时钟周期内为1
assign scantick = (count == SCAN_DIV - 1);

// 每个扫描节拍切换到下一位，依次扫描DK0到DK7
always @(posedge clk or posedge rst) begin
    if (rst) begin
        index <= 3'd0;
        count <= 17'd0;
    end
    else if (scantick) begin
        count <= 17'd0;
        if (index == 3'd7)
            index <= 3'd0;
        else
            index <= index + 3'd1;
    end
    else begin
        count <= count + 17'd1;
    end
end

always @(*) begin
    case (index)
        3'd0: digit = display[3:0];
        3'd1: digit = display[7:4];
        3'd2: digit = display[11:8];
        3'd3: digit = display[15:12];
        3'd4: digit = display[19:16];
        3'd5: digit = display[23:20];
        3'd6: digit = display[27:24];
        3'd7: digit = display[31:28];
        default: digit = 4'h0;
    endcase
end

// EGO1高电平点亮，段码位序为{CA,CB,CC,CD,CE,CF,CG,DP}
always @(*) begin
    case (digit)
        4'h0: seg_code = 8'hFC;
        4'h1: seg_code = 8'h60;
        4'h2: seg_code = 8'hDA;
        4'h3: seg_code = 8'hF2;
        4'h4: seg_code = 8'h66;
        4'h5: seg_code = 8'hB6;
        4'h6: seg_code = 8'hBE;
        4'h7: seg_code = 8'hE0;
        4'h8: seg_code = 8'hFE;
        4'h9: seg_code = 8'hF6;
        4'hA: seg_code = 8'hEE;
        4'hB: seg_code = 8'h3E;
        4'hC: seg_code = 8'h9C;
        4'hD: seg_code = 8'h7A;
        4'hE: seg_code = 8'h9E;
        4'hF: seg_code = 8'h8E;
        default: seg_code = 8'h00;
    endcase
end

// led_en[0]对应右端DK0，led_en[7]对应左端DK7
always @(*) begin
    case (index)
        3'd0: led_en = 8'b0000_0001;
        3'd1: led_en = 8'b0000_0010;
        3'd2: led_en = 8'b0000_0100;
        3'd3: led_en = 8'b0000_1000;
        3'd4: led_en = 8'b0001_0000;
        3'd5: led_en = 8'b0010_0000;
        3'd6: led_en = 8'b0100_0000;
        3'd7: led_en = 8'b1000_0000;
        default: led_en = 8'b0000_0000;
    endcase
end

// cx0连接DK7-DK4，cx1连接DK3-DK0
always @(*) begin
    led_cx0 = 8'b0;
    led_cx1 = 8'b0;
    if (index[2])
        led_cx0 = seg_code;
    else
        led_cx1 = seg_code;
end

endmodule
