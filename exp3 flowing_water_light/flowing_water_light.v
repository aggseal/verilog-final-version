module flowing_water_light #(
    parameter [23:0] cnt_500hz = 24'd200_000 - 1,
    parameter [23:0] cnt_10hz  = 24'd10_000_000 -1,
    parameter integer WIDTH    = 24 
)(
    input wire clk, 
    input wire rst, 
    input wire freq_ctrl, 
    input wire dir_ctrl, 
    input wire mode_sel,
    output reg [7:0] led
);
reg [WIDTH - 1:0] cnt;
reg [23:0]        period_max;
reg               tick;
reg [7:0]         led_position;
wire cnt_end = (cnt >= period_max);

always @(*)
    if (freq_ctrl)  period_max = cnt_10hz;
    else period_max = cnt_500hz;

//生成信号，同时count
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tick <= 0;
        cnt <= {WIDTH{1'b0}};
    end
    else begin
        tick <= 1'b0;
        if (cnt_end) begin
            tick <= 1'b1;
            cnt <= {WIDTH{1'b0}};
        end
        else
        cnt <= cnt + 1;
    end
end

//左移dir_ctrl=1
always @(posedge clk or posedge rst)begin
    if (rst)    led_position <= 8'b1;
    else if (tick)begin
        if (dir_ctrl)   led_position <= {led_position[6:0], led_position[7]};
        else    led_position <= {led_position[0],led_position[7:1]};
    end
end

//分单灯和双灯, mode_sel=1为单灯
always @(*)begin
    if (rst)    led = 8'b1;
    else if (mode_sel)   led = led_position;
    else if (dir_ctrl)  led = led_position | {led_position[6:0], led_position[7]};
    else led = led_position | {led_position[0], led_position[7:1]};
end

endmodule
