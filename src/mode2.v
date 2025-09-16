module top_i2c_oled_mode2(
    clk,
    rst,
    trig_newd,
    I_RH,
    done_send_data,
    done_init,
    state_i2c,
    sda_o,
    sda_i,
    sda_t,
    scl_t,
    en
);
input clk,rst,trig_newd,en;
input [7:0] I_RH;
output reg done_init,done_send_data;
output [3:0] state_i2c;

output sda_o;   // dữ liệu xuất (chỉ khi kéo xuống)
input sda_i;       // dữ liệu đọc từ SDA
output sda_t;   // 1 = High-Z, 0 = drive
output scl_t ;
reg op = 0,newd = 0 ;
reg [6:0] waddr = 7'h3C;
reg [7:0] din;
reg [4:0] num_byte_send = 2, num_byte_read = 2;
reg [3:0] num_char_send = 0;
reg [3:0] i = 0,j = 0;
reg send_firsttime = 0;
wire [3:0] I_RH_chuc, I_RH_dv;
assign I_RH_chuc = I_RH / 10;
assign I_RH_dv = I_RH % 10;
wire done,done_write;
i2c_oled_master ic1(
    .done(done),
    .ack_err(),
    .busy(),
    .clk(clk),
    .rst(rst),
    .op(op),
    .newd(newd),
    .waddr(waddr),
    .din(din),
    .dout(),
    .num_byte_send(num_byte_send),
    .num_byte_read(num_byte_read),
    .state_i2c(state_i2c),
    .done_write(done_write),
    .sda_o(sda_o),
    .sda_i(sda_i),
    .sda_t(sda_t),
    .scl_t(scl_t)
);
reg [7:0] CMD_INIT[0:24];
reg [7:0] CMD_CLEAR[0:2];
reg [7:0] num1_2page [0:1][0:6];

reg [7:0] num0_3page [0:2][0:13];
reg [7:0] num1_3page [0:2][0:13];
reg [7:0] num2_3page [0:2][0:13];
reg [7:0] num3_3page [0:2][0:13]; 
reg [7:0] num4_3page [0:2][0:13];
reg [7:0] num5_3page [0:2][0:13];  
reg [7:0] num6_3page [0:2][0:13];
reg [7:0] num7_3page [0:2][0:13]; 
reg [7:0] num8_3page [0:2][0:13]; 
reg [7:0] num9_3page [0:2][0:13];  
reg [7:0] point_3page [0:2][0:13]; 
reg [7:0] do_3page [0:2][0:13]; 
reg [7:0] percent_3page [0:2][0:13];
reg [7:0] bitmap_send [0:2][0:13]; 
initial begin
   CMD_INIT[0] = 8'hAE; CMD_INIT[1] = 8'hD5;  CMD_INIT[2] = 8'h80;  CMD_INIT[3] = 8'hA8;  CMD_INIT[4] = 8'h3F;  
   CMD_INIT[5] = 8'hD3; CMD_INIT[6] = 8'h00;  CMD_INIT[7] = 8'h40;  CMD_INIT[8] = 8'h8D;  CMD_INIT[9] = 8'h14;  
   CMD_INIT[10] = 8'h20; CMD_INIT[11] = 8'h00;  CMD_INIT[12] = 8'hA1;  CMD_INIT[13] = 8'hC8;  CMD_INIT[14] = 8'hDA; 
   CMD_INIT[15] = 8'h12; CMD_INIT[16] = 8'h81;  CMD_INIT[17] = 8'hCF;  CMD_INIT[18] = 8'hD9;  CMD_INIT[19] = 8'hF1;   
   CMD_INIT[20] = 8'hDB; CMD_INIT[21] = 8'h40;  CMD_INIT[22] = 8'hA4;  CMD_INIT[23] = 8'hA6;  CMD_INIT[24] = 8'hAF;  
   
   CMD_CLEAR[0] = 8'hB0; CMD_CLEAR[1] = 8'h00; CMD_CLEAR[2] = 8'h10; 
//font so dung 3 page
    //num 0 
   num0_3page[0][0] = 8'h00; num0_3page[0][1] = 8'hf8; num0_3page[0][2] = 8'hfc; num0_3page[0][3] = 8'hfe; num0_3page[0][4] = 8'h1e;
   num0_3page[0][5] = 8'h0e; num0_3page[0][6] = 8'h0e; num0_3page[0][7] = 8'h0e; num0_3page[0][8] = 8'h0e; num0_3page[0][9] = 8'h1e;
   num0_3page[0][10] = 8'hfe; num0_3page[0][11] = 8'hfc; num0_3page[0][12] = 8'hf8; num0_3page[0][13] = 8'h00; num0_3page[1][0] = 8'h00;
   num0_3page[1][1] = 8'hff; num0_3page[1][2] = 8'hff; num0_3page[1][3] = 8'hff; num0_3page[1][4] = 8'h00; num0_3page[1][5] = 8'h00;
   num0_3page[1][6] = 8'h00; num0_3page[1][7] = 8'h00;num0_3page[1][8] = 8'h00;num0_3page[1][9] = 8'h00; num0_3page[1][10] = 8'hff;
   num0_3page[1][11] = 8'hff; num0_3page[1][12] = 8'hff; num0_3page[1][13] = 8'h00; num0_3page[2][0] = 8'h00; num0_3page[2][1] = 8'h1f;
   num0_3page[2][2] = 8'h3f; num0_3page[2][3] = 8'h7f; num0_3page[2][4] = 8'h78; num0_3page[2][5] = 8'h70; num0_3page[2][6] = 8'h70;
   num0_3page[2][7] = 8'h70; num0_3page[2][8] = 8'h70; num0_3page[2][9] = 8'h78; num0_3page[2][10] = 8'h7f; num0_3page[2][11] = 8'h3f; 
   num0_3page[2][12] = 8'h1f; num0_3page[2][13] = 8'h00;
    // Số 1
    num1_3page[0][0]  = 8'h00; num1_3page[0][1]  = 8'hC0; num1_3page[0][2]  = 8'hE0; num1_3page[0][3]  = 8'hF0; num1_3page[0][4] = 8'hF8;
    num1_3page[0][5]  = 8'hFC; num1_3page[0][6]  = 8'hFE; num1_3page[0][7]  = 8'hFE; num1_3page[0][8]  = 8'hFE; num1_3page[0][9]  = 8'h00;
    num1_3page[0][10] = 8'h00; num1_3page[0][11] = 8'h00; num1_3page[0][12] = 8'h00; num1_3page[0][13] = 8'h00; num1_3page[1][0]  = 8'h00;
    num1_3page[1][1]  = 8'h00; num1_3page[1][2]  = 8'h00; num1_3page[1][3]  = 8'h00; num1_3page[1][4]  = 8'h00; num1_3page[1][5]  = 8'h00;
    num1_3page[1][6]  = 8'hFF; num1_3page[1][7]  = 8'hFF; num1_3page[1][8]  = 8'hFF; num1_3page[1][9]  = 8'h00; num1_3page[1][10] = 8'h00;
    num1_3page[1][11] = 8'h00; num1_3page[1][12] = 8'h00; num1_3page[1][13] = 8'h00; num1_3page[2][0]  = 8'h00; num1_3page[2][1]  = 8'h70;
    num1_3page[2][2]  = 8'h70; num1_3page[2][3]  = 8'h70; num1_3page[2][4]  = 8'h70; num1_3page[2][5]  = 8'h70; num1_3page[2][6]  = 8'h7F;
    num1_3page[2][7]  = 8'h7F; num1_3page[2][8]  = 8'h7F; num1_3page[2][9]  = 8'h70; num1_3page[2][10] = 8'h70; num1_3page[2][11] = 8'h70;
    num1_3page[2][12] = 8'h70; num1_3page[2][13] = 8'h00;
    // Số 2
    num2_3page[0][0]  = 8'h00; num2_3page[0][1]  = 8'h78; num2_3page[0][2]  = 8'h7C; num2_3page[0][3]  = 8'h3E; num2_3page[0][4]  = 8'h1E;
    num2_3page[0][5]  = 8'h0E; num2_3page[0][6]  = 8'h0E; num2_3page[0][7]  = 8'h0E; num2_3page[0][8]  = 8'h0E; num2_3page[0][9]  = 8'h1E;
    num2_3page[0][10] = 8'h3E; num2_3page[0][11] = 8'hFC; num2_3page[0][12] = 8'hF8; num2_3page[0][13] = 8'h00; num2_3page[1][0]  = 8'h00;
    num2_3page[1][1]  = 8'h00; num2_3page[1][2]  = 8'h00; num2_3page[1][3]  = 8'h00; num2_3page[1][4]  = 8'h80; num2_3page[1][5]  = 8'hC0;
    num2_3page[1][6]  = 8'hE0; num2_3page[1][7]  = 8'hF0; num2_3page[1][8]  = 8'h78; num2_3page[1][9]  = 8'h3C; num2_3page[1][10] = 8'h1E;
    num2_3page[1][11] = 8'h0F; num2_3page[1][12] = 8'h07; num2_3page[1][13] = 8'h00; num2_3page[2][0]  = 8'h00; num2_3page[2][1]  = 8'h7C;
    num2_3page[2][2]  = 8'h7E; num2_3page[2][3]  = 8'h7F; num2_3page[2][4]  = 8'h77; num2_3page[2][5]  = 8'h73; num2_3page[2][6]  = 8'h71;
    num2_3page[2][7]  = 8'h70; num2_3page[2][8]  = 8'h70; num2_3page[2][9]  = 8'h70; num2_3page[2][10] = 8'h78; num2_3page[2][11] = 8'h78;
    num2_3page[2][12] = 8'h78; num2_3page[2][13] = 8'h00;
   //num 3 
   num3_3page[0][0] = 8'h00; num3_3page[0][1] = 8'h00; num3_3page[0][2] = 8'h0e; num3_3page[0][3] = 8'h0e; num3_3page[0][4] = 8'h0e;
   num3_3page[0][5] = 8'h0e; num3_3page[0][6] = 8'h8e; num3_3page[0][7] = 8'hce; num3_3page[0][8] = 8'hee; num3_3page[0][9] = 8'hfe;
   num3_3page[0][10] = 8'hfe; num3_3page[0][11] = 8'h7e; num3_3page[0][12] = 8'h3e; num3_3page[0][13] = 8'h00; num3_3page[1][0] = 8'h00;
   num3_3page[1][1] = 8'h00; num3_3page[1][2] = 8'h00; num3_3page[1][3] = 8'h1c; num3_3page[1][4] = 8'h1e; num3_3page[1][5] = 8'h3f;
   num3_3page[1][6] = 8'h3f; num3_3page[1][7] = 8'h3f; num3_3page[1][8] = 8'h7f;num3_3page[1][9] = 8'h79; num3_3page[1][10] = 8'hf0;
   num3_3page[1][11] = 8'he0; num3_3page[1][12] = 8'hc0; num3_3page[1][13] = 8'h00; num3_3page[2][0] = 8'h00; num3_3page[2][1] = 8'he0;
   num3_3page[2][2] = 8'he0; num3_3page[2][3] = 8'he0; num3_3page[2][4] = 8'he0; num3_3page[2][5] = 8'he0; num3_3page[2][6] = 8'he0;
   num3_3page[2][7] = 8'he0; num3_3page[2][8] = 8'hf0; num3_3page[2][9] = 8'hf8; num3_3page[2][10] = 8'hff; num3_3page[2][11] = 8'h7f; 
   num3_3page[2][12] = 8'h3f; num3_3page[2][13] = 8'h00; 
    // Số 4
    num4_3page[0][0]  = 8'h00; num4_3page[0][1]  = 8'h80; num4_3page[0][2]  = 8'hC0; num4_3page[0][3]  = 8'hE0;
    num4_3page[0][4]  = 8'hF0; num4_3page[0][5]  = 8'h78; num4_3page[0][6]  = 8'h3C; num4_3page[0][7]  = 8'h1E;
    num4_3page[0][8]  = 8'h0E; num4_3page[0][9]  = 8'h06; num4_3page[0][10] = 8'h82; num4_3page[0][11] = 8'h80;
    num4_3page[0][12] = 8'h80; num4_3page[0][13] = 8'h00;   
    num4_3page[1][0]  = 8'h00; num4_3page[1][1]  = 8'hFF; num4_3page[1][2]  = 8'hFF; num4_3page[1][3]  = 8'hFF;
    num4_3page[1][4]  = 8'hE0; num4_3page[1][5]  = 8'hE0; num4_3page[1][6]  = 8'hE0; num4_3page[1][7]  = 8'hE0;
    num4_3page[1][8]  = 8'hE0; num4_3page[1][9]  = 8'hE0; num4_3page[1][10] = 8'hFF; num4_3page[1][11] = 8'hFF;
    num4_3page[1][12] = 8'hFF; num4_3page[1][13] = 8'h00;
    num4_3page[2][0]  = 8'h00; num4_3page[2][1]  = 8'h00; num4_3page[2][2]  = 8'h00; num4_3page[2][3]  = 8'h00;
    num4_3page[2][4]  = 8'h00; num4_3page[2][5]  = 8'h00; num4_3page[2][6]  = 8'h00; num4_3page[2][7]  = 8'h00;
    num4_3page[2][8]  = 8'h00; num4_3page[2][9]  = 8'h7F; num4_3page[2][10] = 8'h7F; num4_3page[2][11] = 8'h7F;
    num4_3page[2][12] = 8'h7F; num4_3page[2][13] = 8'h00;
// Số 5
    num5_3page[0][0]  = 8'h00; num5_3page[0][1]  = 8'hFE; num5_3page[0][2]  = 8'hFE; num5_3page[0][3]  = 8'h0E;
    num5_3page[0][4]  = 8'h0E; num5_3page[0][5]  = 8'h0E; num5_3page[0][6]  = 8'h0E; num5_3page[0][7]  = 8'h0E;
    num5_3page[0][8]  = 8'h0E; num5_3page[0][9]  = 8'h0E; num5_3page[0][10] = 8'h0E; num5_3page[0][11] = 8'h0E;
    num5_3page[0][12] = 8'h00; num5_3page[0][13] = 8'h00;
    
    num5_3page[1][0]  = 8'h00; num5_3page[1][1]  = 8'h07; num5_3page[1][2]  = 8'h0F; num5_3page[1][3]  = 8'h0F;
    num5_3page[1][4]  = 8'h0E; num5_3page[1][5]  = 8'h0E; num5_3page[1][6]  = 8'h0E; num5_3page[1][7]  = 8'h1E;
    num5_3page[1][8]  = 8'h3E; num5_3page[1][9]  = 8'hFC; num5_3page[1][10] = 8'hF8; num5_3page[1][11] = 8'hF0;
    num5_3page[1][12] = 8'hE0; num5_3page[1][13] = 8'h00;
    
    num5_3page[2][0]  = 8'h00; num5_3page[2][1]  = 8'h70; num5_3page[2][2]  = 8'h70; num5_3page[2][3]  = 8'h70;
    num5_3page[2][4]  = 8'h70; num5_3page[2][5]  = 8'h78; num5_3page[2][6]  = 8'h78; num5_3page[2][7]  = 8'h7C;
    num5_3page[2][8]  = 8'h3E; num5_3page[2][9]  = 8'h1F; num5_3page[2][10] = 8'h0F; num5_3page[2][11] = 8'h07;
    num5_3page[2][12] = 8'h03; num5_3page[2][13] = 8'h00;
// Số 6
    num6_3page[0][0]  = 8'h00; num6_3page[0][1]  = 8'hE0; num6_3page[0][2]  = 8'hF0; num6_3page[0][3]  = 8'hF8;
    num6_3page[0][4]  = 8'h7C; num6_3page[0][5]  = 8'h3E; num6_3page[0][6]  = 8'h1E; num6_3page[0][7]  = 8'h0E;
    num6_3page[0][8]  = 8'h0E; num6_3page[0][9]  = 8'h0E; num6_3page[0][10] = 8'h0E; num6_3page[0][11] = 8'h0E;
    num6_3page[0][12] = 8'h00; num6_3page[0][13] = 8'h00;
    
    num6_3page[1][0]  = 8'h00; num6_3page[1][1]  = 8'hFF; num6_3page[1][2]  = 8'hFF; num6_3page[1][3]  = 8'hFF;
    num6_3page[1][4]  = 8'h7C; num6_3page[1][5]  = 8'h3C; num6_3page[1][6]  = 8'h1C; num6_3page[1][7]  = 8'h1C;
    num6_3page[1][8]  = 8'h3C; num6_3page[1][9]  = 8'h7C; num6_3page[1][10] = 8'hFC; num6_3page[1][11] = 8'hF8;
    num6_3page[1][12] = 8'hF0; num6_3page[1][13] = 8'h00;
    
    num6_3page[2][0]  = 8'h00; num6_3page[2][1]  = 8'h1F; num6_3page[2][2]  = 8'h3F; num6_3page[2][3]  = 8'h7F;
    num6_3page[2][4]  = 8'h7C; num6_3page[2][5]  = 8'h78; num6_3page[2][6]  = 8'h70; num6_3page[2][7]  = 8'h70;
    num6_3page[2][8]  = 8'h78; num6_3page[2][9]  = 8'h7C; num6_3page[2][10] = 8'h7F; num6_3page[2][11] = 8'h3F;
    num6_3page[2][12] = 8'h1F; num6_3page[2][13] = 8'h00;

// Số 7
    num7_3page[0][0]  = 8'h00; num7_3page[0][1]  = 8'h0E; num7_3page[0][2]  = 8'h0E; num7_3page[0][3]  = 8'h0E;
    num7_3page[0][4]  = 8'h0E; num7_3page[0][5]  = 8'h0E; num7_3page[0][6]  = 8'h0E; num7_3page[0][7]  = 8'h0E;
    num7_3page[0][8]  = 8'h0E; num7_3page[0][9]  = 8'hFE; num7_3page[0][10] = 8'hFE; num7_3page[0][11] = 8'hFC;
    num7_3page[0][12] = 8'h00; num7_3page[0][13] = 8'h00;
    
    num7_3page[1][0]  = 8'h00; num7_3page[1][1]  = 8'h00; num7_3page[1][2]  = 8'h00; num7_3page[1][3]  = 8'h00;
    num7_3page[1][4]  = 8'hF0; num7_3page[1][5]  = 8'hF8; num7_3page[1][6]  = 8'hFC; num7_3page[1][7]  = 8'hFE;
    num7_3page[1][8]  = 8'h1F; num7_3page[1][9]  = 8'h0F; num7_3page[1][10] = 8'h07; num7_3page[1][11] = 8'h03;
    num7_3page[1][12] = 8'h00; num7_3page[1][13] = 8'h00;
    
    num7_3page[2][0]  = 8'h00; num7_3page[2][1]  = 8'h00; num7_3page[2][2]  = 8'h00; num7_3page[2][3]  = 8'h00;
    num7_3page[2][4]  = 8'h3F; num7_3page[2][5]  = 8'h7F; num7_3page[2][6]  = 8'h7F; num7_3page[2][7]  = 8'h3F;
    num7_3page[2][8]  = 8'h00; num7_3page[2][9]  = 8'h00; num7_3page[2][10] = 8'h00; num7_3page[2][11] = 8'h00;
    num7_3page[2][12] = 8'h00; num7_3page[2][13] = 8'h00;
// Số 8
    num8_3page[0][0]  = 8'h00; num8_3page[0][1]  = 8'hF8; num8_3page[0][2]  = 8'hFC; num8_3page[0][3]  = 8'h1E;
    num8_3page[0][4]  = 8'h0E; num8_3page[0][5]  = 8'h06; num8_3page[0][6]  = 8'h06; num8_3page[0][7]  = 8'h06;
    num8_3page[0][8]  = 8'h06; num8_3page[0][9]  = 8'h0E; num8_3page[0][10] = 8'h1E; num8_3page[0][11] = 8'hFC;
    num8_3page[0][12] = 8'hF8; num8_3page[0][13] = 8'h00;
    
    num8_3page[1][0]  = 8'h00; num8_3page[1][1]  = 8'hC3; num8_3page[1][2]  = 8'hE7; num8_3page[1][3]  = 8'hFF;
    num8_3page[1][4]  = 8'h7E; num8_3page[1][5]  = 8'h3C; num8_3page[1][6]  = 8'h3C; num8_3page[1][7]  = 8'h3C;
    num8_3page[1][8]  = 8'h3C; num8_3page[1][9]  = 8'h7E; num8_3page[1][10] = 8'hFF; num8_3page[1][11] = 8'hE7;
    num8_3page[1][12] = 8'hC3; num8_3page[1][13] = 8'h00;
    
    num8_3page[2][0]  = 8'h00; num8_3page[2][1]  = 8'h1F; num8_3page[2][2]  = 8'h3F; num8_3page[2][3]  = 8'h78;
    num8_3page[2][4]  = 8'h70; num8_3page[2][5]  = 8'h60; num8_3page[2][6]  = 8'h60; num8_3page[2][7]  = 8'h60;
    num8_3page[2][8]  = 8'h60; num8_3page[2][9]  = 8'h70; num8_3page[2][10] = 8'h78; num8_3page[2][11] = 8'h3F;
    num8_3page[2][12] = 8'h1F; num8_3page[2][13] = 8'h00;
// Số 9
    num9_3page[0][0]  = 8'h00; num9_3page[0][1]  = 8'hF8; num9_3page[0][2]  = 8'hFC; num9_3page[0][3]  = 8'hFE;
    num9_3page[0][4]  = 8'h3E; num9_3page[0][5]  = 8'h1E; num9_3page[0][6]  = 8'h0E; num9_3page[0][7]  = 8'h0E;
    num9_3page[0][8]  = 8'h1E; num9_3page[0][9]  = 8'h3E; num9_3page[0][10] = 8'hFE; num9_3page[0][11] = 8'hFC;
    num9_3page[0][12] = 8'hF8; num9_3page[0][13] = 8'h00;
    
    num9_3page[1][0]  = 8'h00; num9_3page[1][1]  = 8'h0F; num9_3page[1][2]  = 8'h1F; num9_3page[1][3]  = 8'h3F;
    num9_3page[1][4]  = 8'h3E; num9_3page[1][5]  = 8'h3C; num9_3page[1][6]  = 8'h38; num9_3page[1][7]  = 8'h38;
    num9_3page[1][8]  = 8'h3C; num9_3page[1][9]  = 8'hBE; num9_3page[1][10] = 8'hFF; num9_3page[1][11] = 8'hFF;
    num9_3page[1][12] = 8'hFF; num9_3page[1][13] = 8'h00;
    
    num9_3page[2][0]  = 8'h00; num9_3page[2][1]  = 8'h70; num9_3page[2][2]  = 8'h70; num9_3page[2][3]  = 8'h70;
    num9_3page[2][4]  = 8'h70; num9_3page[2][5]  = 8'h78; num9_3page[2][6]  = 8'h7C; num9_3page[2][7]  = 8'h7E;
    num9_3page[2][8]  = 8'h3F; num9_3page[2][9]  = 8'h1F; num9_3page[2][10] = 8'h0F; num9_3page[2][11] = 8'h07;
    num9_3page[2][12] = 8'h03; num9_3page[2][13] = 8'h00;
    // ---------------------- point_3page ----------------------
    point_3page[0][0]  = 8'h00; point_3page[0][1]  = 8'h00; point_3page[0][2]  = 8'h00; point_3page[0][3]  = 8'h00;
    point_3page[0][4]  = 8'h00; point_3page[0][5]  = 8'h00; point_3page[0][6]  = 8'h00; point_3page[0][7]  = 8'h00;
    point_3page[0][8]  = 8'h00; point_3page[0][9]  = 8'h00; point_3page[0][10] = 8'h00; point_3page[0][11] = 8'h00;
    point_3page[0][12] = 8'h00; point_3page[0][13] = 8'h00;
    
    point_3page[1][0]  = 8'h00; point_3page[1][1]  = 8'h80; point_3page[1][2]  = 8'h80; point_3page[1][3]  = 8'h80;
    point_3page[1][4]  = 8'h80; point_3page[1][5]  = 8'h80; point_3page[1][6]  = 8'h80; point_3page[1][7]  = 8'h80;
    point_3page[1][8]  = 8'h80; point_3page[1][9]  = 8'h00; point_3page[1][10] = 8'h00; point_3page[1][11] = 8'h00;
    point_3page[1][12] = 8'h00; point_3page[1][13] = 8'h00;
    
    point_3page[2][0]  = 8'h00; point_3page[2][1]  = 8'h7F; point_3page[2][2]  = 8'h7F; point_3page[2][3]  = 8'h7F;
    point_3page[2][4]  = 8'h7F; point_3page[2][5]  = 8'h7F; point_3page[2][6]  = 8'h7F; point_3page[2][7]  = 8'h7F;
    point_3page[2][8]  = 8'h7F; point_3page[2][9]  = 8'h7F; point_3page[2][10] = 8'h00; point_3page[2][11] = 8'h00;
    point_3page[2][12] = 8'h00; point_3page[2][13] = 8'h00;
    
    
    // ---------------------- do_3page ----------------------
    do_3page[0][0]  = 8'h00; do_3page[0][1]  = 8'h3E; do_3page[0][2]  = 8'h22; do_3page[0][3]  = 8'h22;
    do_3page[0][4]  = 8'h3E; do_3page[0][5]  = 8'h00; do_3page[0][6]  = 8'h80; do_3page[0][7]  = 8'h80;
    do_3page[0][8]  = 8'h80; do_3page[0][9]  = 8'h80; do_3page[0][10] = 8'h80; do_3page[0][11] = 8'h80;
    do_3page[0][12] = 8'h00; do_3page[0][13] = 8'h00;
    
    do_3page[1][0]  = 8'h00; do_3page[1][1]  = 8'h00; do_3page[1][2]  = 8'h00; do_3page[1][3]  = 8'hFE;
    do_3page[1][4]  = 8'hFF; do_3page[1][5]  = 8'h07; do_3page[1][6]  = 8'h03; do_3page[1][7]  = 8'h03;
    do_3page[1][8]  = 8'h03; do_3page[1][9]  = 8'h03; do_3page[1][10] = 8'h03; do_3page[1][11] = 8'h03;
    do_3page[1][12] = 8'h00; do_3page[1][13] = 8'h00;
    
    do_3page[2][0]  = 8'h00; do_3page[2][1]  = 8'h00; do_3page[2][2]  = 8'h00; do_3page[2][3]  = 8'h1F;
    do_3page[2][4]  = 8'h3F; do_3page[2][5]  = 8'h78; do_3page[2][6]  = 8'h70; do_3page[2][7]  = 8'h70;
    do_3page[2][8]  = 8'h70; do_3page[2][9]  = 8'h70; do_3page[2][10] = 8'h70; do_3page[2][11] = 8'h30;
    do_3page[2][12] = 8'h00; do_3page[2][13] = 8'h00;
    
    
    // ---------------------- percent_3page ----------------------
    percent_3page[0][0]  = 8'h00; percent_3page[0][1]  = 8'h7E; percent_3page[0][2]  = 8'h7E; percent_3page[0][3]  = 8'h66;
    percent_3page[0][4]  = 8'h66; percent_3page[0][5]  = 8'h7E; percent_3page[0][6]  = 8'h7E; percent_3page[0][7]  = 8'h00;
    percent_3page[0][8]  = 8'h00; percent_3page[0][9]  = 8'h80; percent_3page[0][10] = 8'hC0; percent_3page[0][11] = 8'hE0;
    percent_3page[0][12] = 8'h60; percent_3page[0][13] = 8'h00;
    
    percent_3page[1][0]  = 8'h00; percent_3page[1][1]  = 8'h80; percent_3page[1][2]  = 8'hC0; percent_3page[1][3]  = 8'hE0;
    percent_3page[1][4]  = 8'h70; percent_3page[1][5]  = 8'h38; percent_3page[1][6]  = 8'h1C; percent_3page[1][7]  = 8'h0E;
    percent_3page[1][8]  = 8'h07; percent_3page[1][9]  = 8'h03; percent_3page[1][10] = 8'h01; percent_3page[1][11] = 8'h00;
    percent_3page[1][12] = 8'h00; percent_3page[1][13] = 8'h00;
    
    percent_3page[2][0]  = 8'h00; percent_3page[2][1]  = 8'h01; percent_3page[2][2]  = 8'h01; percent_3page[2][3]  = 8'h00;
    percent_3page[2][4]  = 8'h00; percent_3page[2][5]  = 8'h00; percent_3page[2][6]  = 8'h00; percent_3page[2][7]  = 8'h7E;
    percent_3page[2][8]  = 8'h7E; percent_3page[2][9]  = 8'h66; percent_3page[2][10] = 8'h66; percent_3page[2][11] = 8'h7E;
    percent_3page[2][12] = 8'h7E; percent_3page[2][13] = 8'h00;
end
reg [4:0] count_byte = 5'd0;
reg [4:0] count_byte_cl = 5'd0;
reg [3:0] count_page = 4'd0;
reg [7:0] count_col = 0;
reg [7:0] count_char = 0;
parameter   START_SEND_CMD = 5'd0,
            WAIT_DONE1_SEND_CMD = 5'd1,
            WAIT_DONE0_SEND_CMD = 5'd2,
            START_CLEAR = 5'd3,
            WAIT_DONE1_CLEAR = 5'd4,
            WAIT_DONE0_CLEAR = 5'd5,
            SEND_DATA_CLEAR = 5'd6,
            STOP = 5'd7,
            START_SEND_CMD_CONTROL = 5'd8,
            WAIT_DONE_CMD_CONTROL = 5'd9,
            START_SEND_CMD_CONTROL2 = 5'd10,
            WAIT_DONE_CMD_CONTROL2 = 5'd11,
            START_SEND_DATA_CONTROL = 5'd12,
            WAIT_DONE_DATA_CONTROL = 5'd13,
            WAIT_DONE1_SEND_DATA = 5'd14,
            WAIT_DONE0_SEND_DATA = 5'd15,
            
            START_SEND_CMD_CONTROL3 = 5'd16,
            WAIT_DONE_CMD_CONTROL3 = 5'd17,
            WAIT_DONE1_CMD_CONTROL3 = 5'd18,
            WAIT_DONE0_CMD_CONTROL3 = 5'd19,
            START_SEND_CHAR = 5'd20,
            START_CMD_CONTROL = 5'd21,
            
            WAIT_DONE_DATA_CONTROL3 =5'd22,
            SEND_CHAR = 5'd23,
            WAIT_DONE1_SEND_CHAR = 5'd24,
            WAIT_DONE0_SEND_CHAR = 5'd25,
            DELAY_200MS = 5'd26,
            WAIT_NEWD = 5'd27,
            START = 5'd28;
reg[4:0] state = START;
reg last_sta = 0,cur_sta = 0;
integer count_delay = 0;
always@(posedge clk,posedge rst) begin
    if(rst) begin
        state <= START;
        done_init <= 0;
        done_send_data <= 0;
        count_byte <= 0;
        count_byte_cl <= 0;
        count_page <= 0;
        count_col <= 0;
        newd <= 0 ;
        num_char_send <= 0;
    end
    else begin
        last_sta <= cur_sta;
        cur_sta <= trig_newd;
        case(state)
            START: begin
                if(en) begin 
                    state <= START_SEND_CMD_CONTROL2;
                    send_firsttime <= 0;
                    newd <= 1;
                end
                else
                    state <= START;
            end
            //--------------------------STAGE CLEAR OLED----------------------------------
            START_SEND_CMD_CONTROL2: begin
                din <= 8'h00;
                state <= WAIT_DONE_CMD_CONTROL2;    
            end
            WAIT_DONE_CMD_CONTROL2: begin
                if(done_write)
                    state <= START_CLEAR;   
                else
                    state <= WAIT_DONE_CMD_CONTROL2;   
            end
            START_CLEAR: begin
                if(count_byte_cl == 0) 
                    din <= CMD_CLEAR[count_byte_cl] + count_page;
                else
                    din <= CMD_CLEAR[count_byte_cl];
                op <= 0;
                state <= WAIT_DONE1_CLEAR;
            end
            WAIT_DONE1_CLEAR: begin
                if(done == 1'b1) begin
                    count_byte_cl <= count_byte_cl + 1;
                    state <= WAIT_DONE0_CLEAR;
                end
                else 
                   state <=  WAIT_DONE1_CLEAR;
            end
            WAIT_DONE0_CLEAR: begin
                if(done) begin
                    state <= WAIT_DONE0_CLEAR;
                end
                else begin
                    if(count_byte_cl >= 3) begin
                        state <= START_SEND_DATA_CONTROL;
                        count_byte_cl <= 0;
                    end
                    else 
                        state <= START_SEND_CMD_CONTROL2;
                end
            end
            //------------------- send data clear-------------------------
            START_SEND_DATA_CONTROL: begin 
                din <= 8'h40;
                state <= WAIT_DONE_DATA_CONTROL;  
            end
            WAIT_DONE_DATA_CONTROL: begin
                if(done_write)
                    state <= SEND_DATA_CLEAR;
                else 
                    state <= WAIT_DONE_DATA_CONTROL;
            end
            SEND_DATA_CLEAR: begin
                din <= 8'h00;
                state <= WAIT_DONE1_SEND_DATA;
            end
            WAIT_DONE1_SEND_DATA: begin
                if(done == 1'b1) begin
                    count_col <= count_col + 1;
                    state <= WAIT_DONE0_SEND_DATA;
                end
                else 
                   state <=  WAIT_DONE1_SEND_DATA;
            end
            WAIT_DONE0_SEND_DATA: begin
               if(done) begin
                    state <= WAIT_DONE0_SEND_DATA;
               end
               else begin
                     if(count_col >= 128) begin // sua 128
                        count_page <= count_page + 1;
                        count_col <= 0;
                        if(count_page >= 7) begin
                          state <= WAIT_NEWD;
                          count_page <= 0;
                          num_char_send <= 0;
                          done_init <= 1;
                        end
                        else    
                          state <= START_SEND_CMD_CONTROL2;
                     end
                     else
                        state <= START_SEND_DATA_CONTROL;
               end
            end
            //----------------SEND CHAR--------------------------
            WAIT_NEWD: begin
                done_send_data <= 0;
                if(en) begin
                    if(send_firsttime == 1'b0) begin
                        state <= START_SEND_CMD_CONTROL3;
                        newd <= 1;
                        send_firsttime <= 1;
                    end  
                    else if(last_sta != cur_sta) begin
                        state <= START_SEND_CMD_CONTROL3;
                        newd <= 1;
                    end
                    else 
                        state <= WAIT_NEWD;
                end
                else
                    state <= START;
            end
            START_SEND_CMD_CONTROL3: begin
                din <= 8'h00;
                state <= WAIT_DONE_CMD_CONTROL3;    
            end
            WAIT_DONE_CMD_CONTROL3: begin
                if(done_write)
                    state <= START_CMD_CONTROL;   
                else
                    state <= WAIT_DONE_CMD_CONTROL3;   
            end
            START_CMD_CONTROL: begin
                if(count_byte_cl == 0) begin
                    din <= CMD_CLEAR[count_byte_cl] + count_page + 2; // change theo count_page 
                end
                else if(count_byte_cl == 1)
                    din <= CMD_CLEAR[count_byte_cl] +((num_char_send * 14) & 8'h0f); //change theo vi tri cot
                else 
                    din <= CMD_CLEAR[count_byte_cl] + ((num_char_send *14) >> 4); //change theo vi tri cot
                state <= WAIT_DONE1_CMD_CONTROL3;
            end
            WAIT_DONE1_CMD_CONTROL3: begin
                if(done == 1'b1) begin
                    count_byte_cl <= count_byte_cl + 1;
                    state <= WAIT_DONE0_CMD_CONTROL3;
                end
                else 
                   state <=  WAIT_DONE1_CMD_CONTROL3;
            end
            WAIT_DONE0_CMD_CONTROL3: begin
                if(done) begin
                    state <= WAIT_DONE0_CMD_CONTROL3;
                end
                else begin
                    if(count_byte_cl >= 3) begin
                        state <= START_SEND_CHAR;
                        count_byte_cl <= 0;
                    end
                    else 
                        state <= START_SEND_CMD_CONTROL3;
                end
            end
            //-----------send "H"------------------
            START_SEND_CHAR: begin 
                din <= 8'h40;
                state <= WAIT_DONE_DATA_CONTROL3;  
            end
            WAIT_DONE_DATA_CONTROL3: begin
                if(done_write)
                    state <= SEND_CHAR;
                else 
                    state <= WAIT_DONE_DATA_CONTROL3;
            end
            SEND_CHAR: begin
                if(count_page == 0)
                    din <= bitmap_send[0][count_char];
                else if(count_page == 1)
                    din <= bitmap_send[1][count_char]; 
                else if(count_page == 2)
                    din <= bitmap_send[2][count_char];                    
                state <= WAIT_DONE1_SEND_CHAR;
            end
            WAIT_DONE1_SEND_CHAR: begin
                if(done == 1'b1) begin
                    count_char <= count_char + 1;
                    state <= WAIT_DONE0_SEND_CHAR;
                end
                else 
                   state <=  WAIT_DONE1_SEND_CHAR;
                if(count_char >= 13 & count_page == 2 & num_char_send == 5) newd <= 0;
            end
            WAIT_DONE0_SEND_CHAR: begin
               if(done) begin
                    state <= WAIT_DONE0_SEND_CHAR;
               end
               else begin
                     if(count_char >= 14) begin  
                        count_char <= 0;
                        count_page <= count_page + 1;
                        if(count_page == 2) begin
                            num_char_send <= num_char_send + 1;
                            if(num_char_send == 5) begin
                                state <= STOP;
                                num_char_send <= 0;
                            end
                            else 
                                state <= START_SEND_CMD_CONTROL3;
                            count_page <= 0;
                        end
                        else
                            state <= START_SEND_CMD_CONTROL3;
                     end
                     else
                        state <= START_SEND_CHAR;
               end
            end
            STOP: begin state <= WAIT_NEWD; done_send_data <= 1;  end
        endcase
    end
end
always@(posedge clk, posedge rst) begin
    if(rst) begin
        for(i = 0; i<2;i = i + 1) begin
            for(j = 0; j<14; j = j + 1) begin
                bitmap_send[i][j] <= 8'd0;
            end
        end
    end
    else if(done_write) begin
        for(i = 0; i<3;i = i + 1) begin
            for(j = 0; j<14; j = j + 1) begin
                if(num_char_send == 0) begin
                    case(I_RH_chuc)
                        0: bitmap_send[i][j] <= num0_3page[i][j];
                        1: bitmap_send[i][j] <= num1_3page[i][j];
                        2: bitmap_send[i][j] <= num2_3page[i][j];
                        3: bitmap_send[i][j] <= num3_3page[i][j];
                        4: bitmap_send[i][j] <= num4_3page[i][j];
                        
                        5: bitmap_send[i][j] <= num5_3page[i][j];
                        6: bitmap_send[i][j] <= num6_3page[i][j];
                        7: bitmap_send[i][j] <= num7_3page[i][j];
                        8: bitmap_send[i][j] <= num8_3page[i][j];
                        9: bitmap_send[i][j] <= num9_3page[i][j];
                        default: bitmap_send[i][j] <= num0_3page[i][j];
                    endcase   
                end
                else if(num_char_send == 1) begin
                    case(I_RH_dv)
                        0: bitmap_send[i][j] <= num0_3page[i][j];
                        1: bitmap_send[i][j] <= num1_3page[i][j];
                        2: bitmap_send[i][j] <= num2_3page[i][j];
                        3: bitmap_send[i][j] <= num3_3page[i][j];
                        4: bitmap_send[i][j] <= num4_3page[i][j];
                        5: bitmap_send[i][j] <= num5_3page[i][j];
                        6: bitmap_send[i][j] <= num6_3page[i][j];
                        7: bitmap_send[i][j] <= num7_3page[i][j];
                        8: bitmap_send[i][j] <= num8_3page[i][j];
                        9: bitmap_send[i][j] <= num9_3page[i][j];
                        default: bitmap_send[i][j] <= num0_3page[i][j];
                    endcase   
                end
                else if(num_char_send == 2) begin
                     bitmap_send[i][j] <= point_3page[i][j];
                end
                else if(num_char_send == 3) begin
                     bitmap_send[i][j] <= num0_3page[i][j];
                end
                else if(num_char_send == 4) begin
                     bitmap_send[i][j] <= num0_3page[i][j];
                end
                else if(num_char_send == 5) begin
                     bitmap_send[i][j] <= percent_3page[i][j];
                end
            end
        end
    end
end
endmodule // code chay ngon ne 
