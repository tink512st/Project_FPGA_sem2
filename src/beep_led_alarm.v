module beep_led_alarm(clk,rst,I_Temp,I_RH,I_Temp_war,I_RH_warning,en);
input clk,rst;
input [7:0] I_Temp, I_RH, I_Temp_war, I_RH_warning;
output reg en;

always@(posedge clk,posedge rst) begin
    if(rst)
        en <= 0;
    else if((I_Temp >= I_Temp_war) | (I_RH >= I_RH_warning))
        en <= 1;
    else
        en <= 0;
end
endmodule
