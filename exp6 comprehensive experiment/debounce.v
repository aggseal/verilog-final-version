// debounce : 按键同步消抖；输入 key_in，输出稳定电平 key_clean
module debounce #(
    parameter integer STABLE_CYCLES = 1_000_000
)(
    input  wire clk,
    input  wire rst,
    input  wire key_in,
    output reg  key_clean
);

reg         key_sync_0;
reg         key_sync_1;
reg [19:0]  stable_count;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        key_clean <= 1'b0;
        key_sync_0 <= 1'b0;
        key_sync_1 <= 1'b0;
        stable_count <= 20'b0;
    end 
    else begin
        key_sync_1 <= key_in;
        key_sync_0 <= key_sync_1;

        if (key_sync_0 == key_clean) 
            stable_count <= 20'b0;
        else if (stable_count == STABLE_CYCLES - 1) begin
            key_clean <= key_sync_0;
            stable_count <= 20'b0;
        end
        else
            stable_count <= stable_count + 20'b1;
    end
            
end

endmodule
