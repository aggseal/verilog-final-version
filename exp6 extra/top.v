module top #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer BAUD     = 9_600
)(
    input  wire       clk,
    input  wire       rst,       
    input  wire       key_s2,    // S2：开始/重新开始
    input  wire       uart_rx,   // PC 串口输入，发送 ASCII '1'..'8'
    input  wire       mute_sw,   // SW_DIP0：拨到高电平静音
    output wire       sound_pwm, // 映射到 EGO1 的 LD1_0
    output wire [7:0] led_en,
    output wire [7:0] led_cx0,
    output wire [7:0] led_cx1
);

wire key_s2_clean;
wire key_s2_press;
wire rx_valid;
wire [7:0] rx_data;
wire [31:0] display;
wire [7:0] blank_mask;

debounce #(
    .STABLE_CYCLES(CLOCK_HZ / 100)
) u_debounce_s2 (
    .clk(clk), 
    .rst(rst), 
    .key_in(key_s2), 
    .key_clean(key_s2_clean)
);

edge_detect u_edge_s2 (
    .clk(clk), 
    .rst(rst), 
    .signal_in(key_s2_clean), 
    .rise_pulse(key_s2_press)
);

uart_recv #(
    .CLOCK_HZ(CLOCK_HZ), 
    .BAUD(BAUD)
) u_uart_recv (
    .clk(clk), 
    .rst(rst), 
    .din(uart_rx), 
    .valid(rx_valid), 
    .data(rx_data)
);

whack_a_mole_game #(
    .CLOCK_HZ(CLOCK_HZ)
) u_whack_a_mole_game (
    .clk(clk), 
    .rst(rst), 
    .start(key_s2_press), 
    .mute(mute_sw),
    .rx_valid(rx_valid), 
    .rx_data(rx_data),
    .display(display), 
    .blank_mask(blank_mask), 
    .sound_pwm(sound_pwm)
);

led_ctrl_unit #(
    .SCAN_DIV(CLOCK_HZ / 1000)
) u_led_ctrl_unit (
    .clk(clk), 
    .rst(rst), 
    .display(display), 
    .blank_mask(blank_mask),
    .led_en(led_en), 
    .led_cx0(led_cx0), 
    .led_cx1(led_cx1)
);

endmodule
