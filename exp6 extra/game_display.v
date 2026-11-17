// DK0 显示洞位，DK2-DK3 显示倒计时，DK5-DK6 显示分数
module game_display (
    input  wire [1:0]  state,
    input  wire [7:0]  score,
    input  wire [5:0]  seconds_left,
    input  wire [3:0]  mole_position,
    output reg  [31:0] display,
    output reg  [7:0]  blank_mask
);
localparam [1:0] ST_IDLE = 2'd0, ST_PLAY = 2'd1, ST_END = 2'd2;
reg [7:0] seconds_value;

always @(*) begin
    display = 32'd0;
    blank_mask = 8'hFF;

    // 倒计时：DK2 个位，DK3 十位
    display[11:8]  = seconds_left % 6'd10;
    display[15:12] = seconds_left / 6'd10;

    // 分数：DK5 个位，DK6 十位
    display[23:20] = score % 8'd10;
    display[27:24] = score / 8'd10;
    case (state)
        ST_IDLE : begin
            display[11:8] = 4'd0;
            display[15:12] = 4'd2;
            blank_mask[2] = 1'b0;
            blank_mask[3] = 1'b0;
            blank_mask[5] = 1'b0;
            blank_mask[6] = 1'b0;
        end
        ST_PLAY : begin
            display[3:0] = mole_position;
            blank_mask[0] = 1'b0;
            blank_mask[2] = 1'b0;
            blank_mask[3] = 1'b0;
            blank_mask[5] = 1'b0;
            blank_mask[6] = 1'b0;
        end
        ST_END : begin
            blank_mask[5] = 1'b0;
            blank_mask[6] = 1'b0;
        end
        default : begin
            blank_mask = 8'hFF;
        end
    endcase
end
endmodule
