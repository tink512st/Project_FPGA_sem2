module rotary_encoder(clk,rst,pul_inc,pul_dec,data_a,data_b,clk_1k);
input clk,rst,data_a,data_b;
output reg pul_inc, pul_dec;
output clk_1k;
parameter k = 125_000;
reg data_a_sync1, data_a_sync2, data_b_sync1, data_b_sync2;
parameter   WAIT = 4'd0,
            INCREASE = 4'd1,
            DECREASE = 4'd2,
            
            WAIT_A0_B1 = 4'd3,
            WAIT_A0_B0 = 4'd4,
            WAIT_A1_B0 = 4'd5,
            
            WAIT_B0_A1 = 4'd6,
            WAIT_B0_A0 = 4'd7,
            WAIT_B1_A0 = 4'd8,
            
            WAIT_DATA_1 = 4'd3;
reg [3:0] state = WAIT;
integer counter = 0;
reg clk_1khz = 0;
always@(posedge clk,posedge rst) begin
    if(rst) begin
        counter <= 0;
        clk_1khz <= 0;
    end
    else if(counter >= k/2-1) begin
        clk_1khz <= ~clk_1khz;
        counter <= 0;
    end
    else 
        counter <= counter + 1;
end
always@(posedge clk_1khz, posedge rst) begin
    if(rst) begin
        pul_inc <= 0;
        pul_dec <= 0;
    end
    else begin
        data_a_sync1 <= data_a;
        data_a_sync2 <= data_a_sync1;
        
        data_b_sync1 <= data_b;
        data_b_sync2 <= data_b_sync1;
        
        pul_inc <= 0;
        pul_dec <= 0;
        case(state)
            WAIT: begin
                if(data_a_sync2 == 0 & data_b_sync2 == 1) 
                    state <= INCREASE;
                else if(data_a_sync2 == 1 & data_b_sync2 == 0)
                    state <= DECREASE;
                else 
                    state <= WAIT;
            end
            INCREASE: begin  
                state <= WAIT_A0_B1;
                pul_inc <= 1;
            end
            DECREASE: begin
                pul_dec <= 1;
                state <= WAIT_B0_A1;
            end
            
            WAIT_A0_B1: begin
                pul_inc <= 0;
                    if(data_a_sync2 == 0 & data_b_sync2 == 1) 
                        state <= WAIT_A0_B1;
                    else begin
                        state <= WAIT_A0_B0;
                    end
            end
            WAIT_A0_B0: begin
                    if(data_a_sync2 == 0 & data_b_sync2 == 0) 
                        state <= WAIT_A0_B0;
                    else begin
                        state <= WAIT_A1_B0;
                    end
            end
            WAIT_A1_B0: begin
                    if(data_a_sync2 == 1 & data_b_sync2 == 0) 
                        state <= WAIT_A1_B0;
                    else begin
                        state <= WAIT;
                    end
            end
            
            WAIT_B0_A1: begin
                pul_dec <= 0;
                    if(data_a_sync2 == 1 & data_b_sync2 == 0) 
                        state <= WAIT_B0_A1;
                    else begin
                        state <= WAIT_B0_A0;
                    end
            end
            WAIT_B0_A0: begin
                    if(data_a_sync2 == 0 & data_b_sync2 == 0) 
                        state <= WAIT_B0_A0;
                    else begin
                        state <= WAIT_B1_A0;
                    end
            end
            WAIT_B1_A0: begin
                    if(data_a_sync2 == 0 & data_b_sync2 == 1) 
                        state <= WAIT_B1_A0;
                    else begin
                        state <= WAIT;
                    end
            end
        endcase
    end
end
assign clk_1k = clk_1khz;
endmodule
