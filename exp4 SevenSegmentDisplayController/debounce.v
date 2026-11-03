module debounce #(
    parameter integer STABLE_CYCLES = 1_000_000 
) (
    input  wire clk,
    input  wire rst,
    input  wire key_in,
    output reg  key_clean //稳定后的读数
);
//声明同步寄存器和稳定计数器
reg         key_sync_0;
reg         key_sync_1;
reg [19:0]  stable_count;

always @(posedge clk or posedge rst) begin
    if (rst)begin
        key_clean <= 1'b0;
        key_sync_0 <= 1'b0;
        key_sync_1 <= 1'b0;
        stable_count <= 20'b0;
    end else begin
        key_sync_1 <= key_in;
        key_sync_0 <= key_sync_1; //延迟一拍送入sync0，避免亚稳态（时钟沿附近变化）
                                   

        if (key_sync_0 == key_clean)        
            stable_count <= 20'b0;
        else if (stable_count == STABLE_CYCLES - 1) begin
            stable_count <= 20'b0;
            key_clean <= key_sync_0;
        end
        else
            stable_count <= stable_count + 20'b1;
    end
end

endmodule