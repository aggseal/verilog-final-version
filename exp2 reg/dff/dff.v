module dff (
    input      clk,
    input      clr,
    input      en ,
    input      d  ,
    output reg q
);
always @ (posedge clk or posedge clr) begin
    if (clr)    q <= 1'b0;
    else if (en)    q <= d;
end
endmodule