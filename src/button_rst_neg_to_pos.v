module button_rst_neg_to_pos(clk,rst_in,rst_pos);
input clk,rst_in;
output reg rst_pos;
always@(posedge clk, negedge rst_in) begin
    if(rst_in == 0)
        rst_pos <= 1;
    else 
        rst_pos <= 0;
end
endmodule
