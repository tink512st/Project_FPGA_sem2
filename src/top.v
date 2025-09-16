module top(sda,scl,clk,rst,donerx,donetx,doutrx,dintx,newd_uart_tx,mode,trig_newd12,I_Temp_war,I_Hum_war,en_war);
input clk,rst;
input [1:0] mode;
input trig_newd12;
input [6:0] I_Temp_war, I_Hum_war;
output scl;
inout sda;
input donerx,donetx;
input [7:0] doutrx;
output reg [7:0] dintx;
output newd_uart_tx;
output en_war;
    reg newd_aht20 = 0, newd_tx = 0;
    reg [2:0] count_byte = 0;
    reg cur = 0,last = 0;
    reg [7:0] I_Temp,D_Temp,I_RH,D_RH;
    wire [13:0] temp,hum;
    wire sda_o_oled,sda_i_oled,sda_t_oled,scl_t_oled;
    wire sda_o_sensor,sda_i_sensor,sda_t_sensor,scl_t_sensor;
    reg sel_slave = 1; 
    reg trig_newd = 0;
    wire done_send_data,done_init;
// --- IOBUF cho SDA ---
wire  sda_o ;   // dữ liệu xuất (chỉ khi kéo xuống)
wire sda_i;       // dữ liệu đọc từ SDA
wire  sda_t ;   // 1 = High-Z, 0 = drive
IOBUF sda_iobuf (
    .I(sda_o),  // data output
    .O(sda_i),  // data input
    .T(sda_t),  // 1 = High-Z, 0 = drive
    .IO(sda)    // pin vật lý
);
i2c_aht20 ic1(
    .done(done_measure),
    .ack_err(),
    .busy(),
    .clk(clk),
    .rst(rst),
    .newd(newd_aht20),
    .humidity_vl(hum),
    .temp_vl(temp),
    .stage(),
    .state_send_sen(),
    .sda_o(sda_o_sensor),
    .sda_i(sda_i_sensor),
    .sda_t(sda_t_sensor),
    .scl_t(scl_t_sensor)
);

top_oled ic2(
    .clk(clk),
    .rst(rst),
    .trig_newd0(trig_newd),
    .trig_newd12(trig_newd12),
    .I_Temp_war(I_Temp_war),
    .I_Hum_war(I_Hum_war),
    .I_Temp(I_Temp),
    .D_Temp(D_Temp),
    .I_RH(I_RH),
    .D_RH(D_RH),
    .done_send_data(done_send_data),
    .done_init(done_init),
    .mode(mode),
    .state_i2c(),
    .sda_o(sda_o_oled),
    .sda_i(sda_i_oled),
    .sda_t(sda_t_oled),
    .scl_t(scl_t_oled)
 );
beep_led_alarm ic3(.clk(clk),.rst(rst),.I_Temp(I_Temp),.I_RH(I_RH),.I_Temp_war(I_Temp_war),.I_RH_warning(I_Hum_war),.en(en_war));
parameter   START_AHT20 = 4'd0,
            WAIT_MEASURE = 4'd1,
            SEND_VL_LCD = 4'd2,
            WAIT_LCD = 4'd3,
            SET_NEWD_TO_0 = 4'd4,
            DISPLAY_ROW0 = 4'd5,
            DISPLAY_ROW1 = 4'd6,
            WAIT_LCD2 = 4'd7,
            WAIT_3S = 4'd8,
            SEND_UART = 4'd9,
            WAIT_SEND_2BYTE = 4'd10,
            WAIT_DONE_TX = 4'd11,
            DISPLAY_OLED = 4'd12,
            WAIT_INIT_OLED = 4'd13,
            TRIG_NEWD_OLED = 4'd14,
            WAIT_MODE0 = 4'd15;
integer count = 0;
reg [3:0] state = WAIT_INIT_OLED;
always@(posedge clk, posedge rst) begin
    if(rst) begin
        state <= WAIT_INIT_OLED;
        newd_aht20 <= 0;
        count <= 0;
        newd_tx <= 0;
        I_Temp <=0;
        D_Temp <= 0;
        I_RH <= 0;
        D_RH <= 0;
        count_byte <= 0;
        sel_slave <= 1;
    end
    else begin
        case(state) 
            WAIT_INIT_OLED: begin
                if(done_init) begin
                    state <=  START_AHT20;
                    sel_slave <= 0;
                end
                else
                     state <=  WAIT_INIT_OLED;
            end
            START_AHT20: begin
                    newd_aht20 <= 1;
                    state <=  WAIT_MEASURE;
                    count_byte <= 0;
                    sel_slave <= 0;
            end
            WAIT_MEASURE: begin
                if(done_measure == 1) begin        
                    newd_aht20 <= 0;           
                    sel_slave <= 1'b1;
                    if(mode == 2'd0) begin
                        state <= TRIG_NEWD_OLED;
                        I_Temp <= temp / 100;
                        D_Temp <= temp % 100;
                        I_RH <= hum / 100;
                        D_RH <= hum % 100; 
                    end
                    else begin
                        state <= WAIT_MODE0;
                    end
                end
                else    
                    state <= WAIT_MEASURE;
            end
            WAIT_MODE0: begin
                if(mode == 2'd0) begin
                    state <= TRIG_NEWD_OLED;
                    I_Temp <= temp / 100;
                    D_Temp <= temp % 100;
                    I_RH <= hum / 100;
                    D_RH <= hum % 100; 
                end
                else begin
                    state <= WAIT_MODE0;
                end
            end
            TRIG_NEWD_OLED: begin
                trig_newd <= !trig_newd;
                state <= DISPLAY_OLED;
            end
            DISPLAY_OLED: begin
                if(done_send_data) begin
                    state <= SEND_UART;
                    dintx <= {1'b0,I_Temp[6:0]};
                end
                else 
                    state <= DISPLAY_OLED;
            end
            SEND_UART: begin
                newd_tx <= 1;
                count_byte <= count_byte + 1;
                state <= WAIT_DONE_TX;
            end
            WAIT_DONE_TX: begin
                if(donetx == 1'b0) begin
                    state <= WAIT_DONE_TX;
                end
                else 
                    state <= WAIT_SEND_2BYTE;
            end
            WAIT_SEND_2BYTE: begin
                if(count_byte >= 4) begin
                    state <= WAIT_3S;
                    newd_tx <= 0;
                end
                else if(count_byte < 4 & donetx == 1'b1) begin
                    state <= WAIT_SEND_2BYTE;
                    case(count_byte)
                        3'd0: dintx <= {1'b0,I_Temp[6:0]};
                        3'd1: dintx <= {1'b0,D_Temp[6:0]};
                        3'd2: dintx <= {1'b1,I_RH[6:0]};
                        3'd3: dintx <= {1'b1,D_RH[6:0]};
                        default: dintx <= {1'b0,I_Temp[6:0]};
                    endcase
                end
                else    
                    state <= SEND_UART;
            end
            WAIT_3S: begin
                sel_slave <= 1'b0; // chuyen drive aht20
                if(mode == 2'd0) 
                    if(count < 375_000_000) begin // doi khi mo phong 375_000_000
                        state <= WAIT_3S;
                        count <= count + 1;
                    end
                    else begin
                        state <= START_AHT20;
                        count <= 0;
                    end
                else begin
                    sel_slave <= 1'b1;
                    count <= 0;
                    state <= WAIT_MODE0;
                end 
            end
        endcase
     end
end
assign newd_uart_tx = newd_tx;
assign scl = (sel_slave == 1'b0) ? scl_t_sensor : scl_t_oled;  
assign sda_o = (sel_slave == 1'b0) ? sda_o_sensor : sda_o_oled;  
assign sda_i_sensor = (sel_slave == 1'b0) ? sda_i  : 1'b0;
assign sda_i_oled   = (sel_slave == 1'b1) ? sda_i  : 1'b0;
assign sda_t = (sel_slave == 1'b0) ? sda_t_sensor : sda_t_oled;  
//assign sda = (sda_t == 1'b0 & sda_o == 1'b0) ? 1'b0 :(sda_t == 1'b1) ? 1'b1 : 1'bz;
//assign sda_i = sda;
endmodule
