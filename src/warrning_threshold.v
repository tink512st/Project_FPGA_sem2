module threshold_warning(clk,rst,pul_inc,pul_dec,trig_newd,I_RH,I_Temp,mode);
input clk,rst,pul_inc,pul_dec;
input [1:0] mode;
output reg trig_newd;
output [7:0]I_Temp;
output [7:0]I_RH;
reg [7:0] value_war_temp = 26;
reg [7:0] value_war_hum = 60;
always@(posedge clk,posedge rst) begin
    if(rst) begin
        trig_newd <= 0;
        value_war_temp <= 26;
        value_war_hum <= 60;
    end
    else if(pul_inc) begin
        trig_newd <= ~trig_newd;
        if(mode == 2'd1)
            value_war_temp <= value_war_temp + 1;
        else if(mode == 2'd2)
            value_war_hum <= value_war_hum + 1;   
    end
    else if(pul_dec) begin
        trig_newd <= ~trig_newd;
        if(mode == 2'd1)
            value_war_temp <= value_war_temp - 1;
        else if(mode == 2'd2)
            value_war_hum <= value_war_hum - 1; 
    end
end 
assign I_Temp = value_war_temp;
assign I_RH = value_war_hum;
endmodule
