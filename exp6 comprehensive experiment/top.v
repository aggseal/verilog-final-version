// 设计层次 / 接口方向：
//   key_s2 -> debounce.key_clean -> edge_detect.rise_pulse -> tx_controller.start
//   tx_controller.tx_valid/tx_data -> uart_send.valid/data -> uart_tx
//   uart_send.done -> tx_controller.tx_done -> tx_controller.sent_count
//   uart_rx -> uart_recv.din -> uart_recv.valid/data -> uart_display -> display
//   display -> led_ctrl_unit -> led_en/led_cx0/led_cx1（数码管）
module top #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer BAUD     = 9_600,
    parameter [15:0] EXP_GROUP  = "19",
    parameter [79:0] STUDENT_ID = "2025311563"
)(
    input  wire       clk,
    input  wire       rst,       // 内部约定高有效异步复位
    input  wire       key_s2,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led_en,
    output wire [7:0] led_cx0,
    output wire [7:0] led_cx1
);

wire       key_s2_clean;
wire       key_s2_press;
wire       rx_valid;
wire [7:0] rx_data;
wire       tx_valid;
wire [7:0] tx_data;
wire       tx_done;
wire [7:0] sent_count;
wire [31:0] display;
wire [7:0]  blank_mask; // bit i=1 表示 DK i 应完全熄灭

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

tx_controller #(
    .CLOCK_HZ(CLOCK_HZ), 
    .EXP_GROUP(EXP_GROUP), 
    .STUDENT_ID(STUDENT_ID)
) u_tx_controller (
    .clk(clk), 
    .rst(rst), 
    .start(key_s2_press),
    .tx_done(tx_done), 
    .tx_valid(tx_valid), 
    .tx_data(tx_data),
    .sent_count(sent_count)
);

uart_send #(
    .CLOCK_HZ(CLOCK_HZ), 
    .BAUD(BAUD)
) u_uart_send (
    .clk(clk), 
    .rst(rst), 
    .valid(tx_valid), 
    .data(tx_data),
    .dout(uart_tx), 
    .done(tx_done)
);

uart_display u_uart_display (
    .clk(clk), 
    .rst(rst), 
    .rx_valid(rx_valid), 
    .rx_data(rx_data),
    .sent_count(sent_count), 
    .display(display),
    .blank_mask(blank_mask)
);

led_ctrl_unit u_led_ctrl_unit (
    .clk(clk), 
    .rst(rst), 
    .display(display),
    .blank_mask(blank_mask),
    .led_en(led_en), 
    .led_cx0(led_cx0), 
    .led_cx1(led_cx1)
);

endmodule
