module reg8file (
    input  wire clk,  
    input  wire clr,    
    input  wire en,
    input  wire [7:0] d,
    input  wire [2:0] wsel,
    input  wire [2:0] rsel,
    output reg  [7:0] q    
);

reg [7:0] regs[0:7];
integer i;

always @ (posedge clk or posedge clr) begin
    if (clr) begin
        for (i = 0; i < 8; i = i + 1)
        regs[i] <= 8'b0000_0000;
    end
    else if (en)
    regs[wsel] <= d;
end

always @(*) 
    q = regs[rsel];

endmodule