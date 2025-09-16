module top_oled(
    clk,
    rst,
    trig_newd0,
    trig_newd12,
    I_Temp_war,
    I_Hum_war,
    I_Temp,
    D_Temp,
    I_RH,
    D_RH,
    done_send_data,
    done_init,
    mode,
    state_i2c,
    sda_o,
    sda_i,
    sda_t,
    scl_t
 );
input clk,rst, trig_newd0, trig_newd12;
input [7:0] I_Temp_war, I_Hum_war;
input [1:0] mode;
output done_send_data,done_init;
input [7:0] I_Temp, D_Temp, I_RH, D_RH;
output [3:0] state_i2c;
output sda_o;   
input sda_i;       
output sda_t;   
output scl_t ;
wire trig_newd1,trig_newd2;
wire [3:0] state_i2c_mode0,state_i2c_mode1;
//assign sda = (sda_t == 1'b0 & sda_o == 1'b0) ? 1'b0 :(sda_t == 1'b1) ? 1'b1 : 1'bz;
//assign sda_i = sda;
//IOBUF sda_iobuf (
//    .I(sda_o),  // data output
//    .O(sda_i),  // data input
//    .T(sda_t),  // 1 = High-Z, 0 = drive
//    .IO(sda)    // pin vật lý
//);
wire sda_o_mode0;   // dữ liệu xuất (chỉ khi kéo xuống)
wire sda_i_mode0;       // dữ liệu đọc từ SDA
wire sda_t_mode0;   // 1 = High-Z, 0 = drive
wire scl_t_mode0;

wire sda_o_mode1;   // dữ liệu xuất (chỉ khi kéo xuống)
wire sda_i_mode1;       // dữ liệu đọc từ SDA
wire sda_t_mode1;   // 1 = High-Z, 0 = drive
wire scl_t_mode1;

wire sda_o_mode2;   // dữ liệu xuất (chỉ khi kéo xuống)
wire sda_i_mode2;       // dữ liệu đọc từ SDA
wire sda_t_mode2;   // 1 = High-Z, 0 = drive
wire scl_t_mode2;

reg en_mode0 = 1,en_mode1 = 0, en_mode2 = 0;
wire done_send_data_mode0, done_init_mode0, done_send_data_mode1, done_init_mode1,done_send_data_mode2, done_init_mode2;
top_i2c_oled_mode0 mode0(
    .clk(clk),
    .rst(rst),
    .trig_newd(trig_newd0),
    .I_Temp(I_Temp),
    .D_Temp(D_Temp),
    .I_RH(I_RH),
    .D_RH(D_RH),
    .done_send_data(done_send_data_mode0),
    .done_init(done_init_mode0),
    .sda_o(sda_o_mode0),
    .sda_i(sda_i_mode0),
    .sda_t(sda_t_mode0),
    .scl_t(scl_t_mode0),
    .en(en_mode0),
    .state_i2c(state_i2c_mode0),
    .warning_temp(I_Temp_war),
    .warning_hum(I_Hum_war)
);

top_i2c_oled_mode1 mode1(
    .clk(clk),
    .rst(rst),
    .trig_newd(trig_newd1),
    .I_Temp(I_Temp_war),
    .done_send_data(done_send_data_mode1),
    .done_init(done_init_mode1),
    .state_i2c(state_i2c_mode1),
    .sda_o(sda_o_mode1),
    .sda_i(sda_i_mode1),
    .sda_t(sda_t_mode1),
    .scl_t(scl_t_mode1),
    .en(en_mode1)
);

top_i2c_oled_mode2 mode2(
    .clk(clk),
    .rst(rst),
    .trig_newd(trig_newd2),
    .I_RH(I_Hum_war),
    .done_send_data(done_send_data_mode2),
    .done_init(done_init_mode2),
    .state_i2c(state_i2c_mode2),
    .sda_o(sda_o_mode2),
    .sda_i(sda_i_mode2),
    .sda_t(sda_t_mode2),
    .scl_t(scl_t_mode2),
    .en(en_mode2)
);
always@(posedge clk, posedge rst) begin
    if(rst) begin
        en_mode0 <= 1;
        en_mode1 <= 0;
    end       
    else begin
        if(mode == 2'd0) begin
            en_mode0 <= 1;
            en_mode1 <= 0;
            en_mode2 <= 0;
        end
        else if(mode == 2'd1) begin
            en_mode0 <= 0;
            en_mode1 <= 1;
            en_mode2 <= 0;
        end
        else if(mode == 2'd2) begin
            en_mode0 <= 0;
            en_mode1 <= 0;
            en_mode2 <= 1;
        end
    end   
end
assign sda_o = (mode == 2'd0) ? sda_o_mode0 : (mode == 2'd1) ? sda_o_mode1 : sda_o_mode2;   

assign sda_i_mode0 = (mode == 2'd0) ? sda_i: 1'bz;  
assign sda_i_mode1 = (mode == 2'd1) ? sda_i: 1'bz;   
assign sda_i_mode2 = (mode == 2'd2) ? sda_i: 1'bz;    

assign sda_t = (mode == 2'd0) ? sda_t_mode0 : (mode == 2'd1) ? sda_t_mode1 : sda_t_mode2;   
assign scl_t = (mode == 2'd0) ? scl_t_mode0 : (mode == 2'd1) ? scl_t_mode1 : scl_t_mode2;
assign done_send_data = (mode == 2'd0) ? done_send_data_mode0 : (mode == 2'd1) ? done_send_data_mode1 : done_send_data_mode2; 
assign done_init = (mode == 2'd0) ? done_init_mode0 : (mode == 2'd1) ? done_init_mode1 : done_init_mode2;
assign state_i2c = (mode == 2'd0) ? state_i2c_mode0 : (mode == 2'd1) ? state_i2c_mode1 : state_i2c_mode2;
//assign scl = scl_t;
assign trig_newd1 = (mode == 2'd1) ? trig_newd12 : 1'bz;
assign trig_newd2 = (mode == 2'd2) ? trig_newd12 : 1'bz;
endmodule
