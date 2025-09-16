module div_clk_5hz(
    input  wire clk, 
    input  wire rst, 
    input  wire en,
    output reg  clk_5hz
);
    parameter K = 125_000_000 / 5;   // 25,000,000
    reg [24:0] count;                // đủ chứa giá trị tới 25M

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_5hz <= 0;
            count   <= 0;
        end 
        else if (en) begin
            if (count == (K/2 - 1)) begin
                count   <= 0;
                clk_5hz <= ~clk_5hz;
            end else begin
                count <= count + 1;
            end
        end
        else 
            clk_5hz <= 0;
    end
endmodule
