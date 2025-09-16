module i2c_aht20(
    done,
    ack_err,
    busy,
    clk,
    rst,
    newd,
    humidity_vl,
    temp_vl,
    stage,
    state_send_sen,
    sda_o,
    sda_i,
    sda_t,
    scl_t
);

input clk,rst,newd;
output [13:0] temp_vl;
output [13:0] humidity_vl;
output reg done, ack_err, busy;
output [1:0] stage;
output reg [3:0] state_send_sen;
output reg  sda_o;   
input sda_i;      
output reg  sda_t;   
output reg  scl_t;

parameter sys_freq = 125_000_000;//125_000_000
parameter i2c_freq = 400_000;//400_000

parameter delay_45ms = 5_625_000; //5_625_000
parameter delay_20ms = 2_500_000; // 2_500_000
parameter delay_200ms = 25_000_000; // 25_000_000
parameter clk_count4 = sys_freq / i2c_freq;
parameter clk_count1 = clk_count4/4;

// --- IOBUF cho SDA ---
//reg  sda_o = 0;   // dữ liệu xuất (chỉ khi kéo xuống)
//wire sda_i;       // dữ liệu đọc từ SDA
//reg  sda_t = 1;   // 1 = High-Z, 0 = drive
//reg  scl_t = 0;
reg [1:0] stagew = 2'b00;
//IOBUF sda_iobuf (
//    .I(sda_o),  // data output
//    .O(sda_i),  // data input
//    .T(sda_t),  // 1 = High-Z, 0 = drive
//    .IO(sda)    // pin vật lý
//);

// ----------------------------------------------------
reg [1:0] pulse;
integer count1 = 0;
integer count_delay = 0;
reg [3:0] count_byte = 0;
reg [7:0] data_receive [0:6];
reg [7:0] data_send [0:2];
wire [19:0] temp_raw;
wire [19:0] hum_raw;

parameter CMD_INIT = 8'hbe,
          CMD_INIT_BYTE1 = 8'h08,
          CMD_INIT_BYTE2 = 8'h00,
          CMD_MEASURE = 8'hAC,
          CMD_MEASURE_BYTE1 = 8'h33,
          CMD_MEASURE_BYTE2 = 8'h00,
          ADD_WRITE = 8'h70,
          ADD_READ = 8'h71;
// Tạo trạng thái xung
always @(posedge clk) begin
    if(rst) begin
        pulse <= 0;
        count1 <= 0;
    end
    else if(busy == 0) begin
        pulse <= 0;
        count1 <= 0;
    end
    else if(count1 == clk_count1-1) begin
        pulse <= 1;
        count1 <= count1+1;
    end
    else if(count1 == clk_count1*2-1) begin
        pulse <= 2;
        count1 <= count1+1;
    end
    else if(count1 == clk_count1*3-1) begin
        pulse <= 3;
        count1 <= count1+1;
    end
    else if(count1 == clk_count1*4-1) begin
        pulse <= 0;
        count1 <= 0;
    end
    else begin
        count1 <= count1 + 1;
    end
end

parameter SCALE = 1<<20;//2^20
parameter IDLE = 4'd0, 
          START = 4'd1, 
          WRITE_ADD = 4'd2, 
          ACK_1 = 4'd3, 
          WRITE_DATA = 4'd4, 
          ACK = 4'd5, 
          STOP = 4'd8, 
          MASTER_NACK = 4'd9,
          READ_DATA = 4'd10,
          MASTER_ACK = 4'd11,
          WAIT_45MS_INIT = 4'd12,
          WAIT_15MS_AFTER_INIT = 4'd13,
          WAIT_MEASURE_90MS = 4'd14;

reg[3:0] state = IDLE;

reg [7:0]tx_data = 0,rx_data = 0;
reg [7:0] add = 0;
reg r_ack = 0;
reg [3:0] bit_count;

always@(posedge clk or posedge rst) begin
    if(rst) begin
        state <= WAIT_45MS_INIT;
        bit_count <= 0;
        count_byte <= 0;
        count_delay<= 0;
        sda_t <= 1;   // nhả SDA
        sda_o <= 0;
        scl_t <= 0;
        tx_data <= 0;
        add <= 0;
        ack_err <= 0;
        busy <= 0;
        done <= 0;
        stagew <= 2'b00;
    end
    else 
       case(state) 
            WAIT_45MS_INIT: begin
                state_send_sen <= 4'b0000;
                if(count_delay < delay_45ms) begin
                    count_delay <= count_delay + 1;
                end
                else begin
                    count_delay <= 0;
                    state <= IDLE;
                end
            end
            IDLE: begin
                state_send_sen <= 4'b0001;
                done <= 0;
                if(newd) begin
                    state <= START;
                    if(stage == 2'b00 || stage == 2'b01) add <= ADD_WRITE;
                    else add <= ADD_READ;
                    busy <= 1;
                    ack_err <= 0;
                end
                else begin
                    tx_data <= 0;
                    add <= 0;
                    busy <= 0;
                    ack_err <= 0;
                    stagew <= 2'b00;
                end
            end
            START: begin
                state_send_sen <= 4'b0010;
                case(pulse)
                    0,1: begin sda_t <= 1; scl_t <= 1; end 
                    2,3: begin sda_t <= 0; sda_o <= 0; scl_t <= 1; end 
                endcase
                if(count1 == clk_count1*4-1) begin
                    state <= WRITE_ADD;
                    scl_t <= 0;
                end
            end
            WRITE_ADD: begin
                state_send_sen <= 4'b0011;
                if(bit_count<=7) begin
                    case(pulse) 
                        0: begin scl_t <= 0; end
                        1: begin scl_t <= 0;
                            if(add[7-bit_count]==1'b0) begin sda_t <= 0; sda_o <= 0; end
                            else sda_t <= 1;
                        end
                        2,3: begin scl_t <= 1; end
                    endcase
                    if(count1 == clk_count1*4-1) begin
                        bit_count <= bit_count + 1;
                        scl_t <= 0;
                    end
                end
                else begin
                    bit_count <= 0;
                    state <= ACK_1;
                    scl_t <= 0;
                    sda_t <= 1; 
//                    sda_o <= 0; sda_t <= 0;
                end
            end
            ACK_1: begin
                state_send_sen <= 4'b0100;
                sda_t <= 1;
//                sda_o <= 0; sda_t <= 0;
                case(pulse) 
                    0,1: scl_t <= 0;
                    2: begin scl_t <= 1; r_ack <= sda_i; end
                    3: scl_t <= 1;
                endcase
                if(count1 == clk_count1*4-1) begin
                    if(r_ack == 0 && add[0] == 0) begin
                        state <= WRITE_DATA;
                        if(stage == 2'b00) begin
                            data_send[0] <= CMD_INIT;
                            data_send[1] <= CMD_INIT_BYTE1;
                            data_send[2] <= CMD_INIT_BYTE2;
                        end
                        else if(stage == 2'b01) begin
                            data_send[0] <= CMD_MEASURE;
                            data_send[1] <= CMD_MEASURE_BYTE1;
                            data_send[2] <= CMD_MEASURE_BYTE2;
                        end
                        bit_count <= 0;
                    end
                    else if(r_ack == 0 && add[0] == 1) begin
                        state <= READ_DATA;
                        bit_count <= 0;
                    end
                    else begin
                        state <= STOP;
                        ack_err <= 1;
                    end
                end
            end
            WRITE_DATA: begin
                state_send_sen <= 4'b0101;
                if(bit_count == 0) begin
                    tx_data <= data_send[count_byte];  // load byte mới
                end 
                if(bit_count <= 7) begin
                    case(pulse) 
                        0: scl_t <= 0;
                        1: begin scl_t <= 0;
                            if(tx_data[7-bit_count]==1'b0) begin sda_t <= 0; sda_o <= 0; end
                            else sda_t <= 1;
                        end
                        2,3: scl_t <= 1;
                    endcase
                    if(count1 == clk_count1*4-1) begin
                        bit_count <= bit_count + 1;
                        scl_t <= 0;
                    end
                end
                else begin
                    state <= ACK;
                    bit_count <= 0;
                    sda_t <= 1;
//                    sda_o <= 0; sda_t <= 0;
                end
            end
            ACK: begin
                state_send_sen <= 4'b0110;
                sda_t <= 1;
//                sda_o <= 0; sda_t <= 0;
                case(pulse) 
                    0,1: scl_t <= 0;
                    2: begin scl_t <= 1; r_ack <= sda_i; end
                    3: scl_t <= 1;
                endcase
                if(count1 == clk_count1*4-1) begin
                    count_byte <= count_byte + 1;
                    if(r_ack == 0) begin
                        if(count_byte == 2) begin
                             state <= STOP;
                             count_byte <= 0;
                        end
                        else 
                            state <= WRITE_DATA;
                        bit_count <= 0;
                    end
                    else begin
                        state <= STOP;
                        ack_err <= 1;
                    end
                end
            end
            READ_DATA: begin
                state_send_sen <= 4'b0111;
                sda_t <= 1;
                if(bit_count <= 7) begin
                    case(pulse) 
                        0,1: scl_t <= 0;
                        2: begin scl_t <= 1;
                            if(count1 == clk_count1*2 + clk_count1/2)
                                rx_data <= {rx_data[6:0],sda_i};
                        end
                        3: scl_t <= 1;
                    endcase
                    if(count1 == clk_count1*4-1) begin
                        bit_count <= bit_count + 1;
                        scl_t <= 0;
                    end
                end
                else begin
                    data_receive[count_byte] <= rx_data;
                    count_byte <= count_byte + 1;
                    bit_count <= 0;
                    if(count_byte < 6) 
                        state <= MASTER_ACK;
                    else begin
                        state <= MASTER_NACK;
                        count_byte <= 0;
                    end
                end
            end
            MASTER_ACK: begin
                state_send_sen <= 4'b1000;
                case(pulse)
                    0: begin scl_t <= 0; sda_t <= 0; sda_o <= 0; end
                    1: scl_t <= 0;
                    2: scl_t <= 1;
                    3: scl_t <= 1;
                endcase
                if(count1 == clk_count1*4-1) begin
                    state <= READ_DATA;
                    sda_t <= 1;
                    scl_t <= 0;
                end
            end
            MASTER_NACK: begin
                state_send_sen <= 4'b1001;
                sda_t <= 1;
                case(pulse) 
                    0,1,2,3: begin sda_t <= 1; scl_t <= (pulse>=2)?1:0; end
                endcase
                if(count1== clk_count1*4-1) begin
                    scl_t <= 1;
                    sda_t <= 0; sda_o <= 0;
                    count_byte <= 0;
                    state <= STOP;
                    if(stagew == 2'b10) done <= 1'b1;
                end
            end
            STOP: begin
                state_send_sen <= 4'b1010;
                case(pulse) 
                    0: begin scl_t <= 0; sda_t <= 0; sda_o <= 0; end
                    1: begin scl_t <= 1; sda_t <= 0; sda_o <= 0; end
                    2,3: begin scl_t <= 1; sda_t <= 1; end
                endcase
                if(count1== clk_count1*4-1) begin
                    if(stage == 2'b00) begin
                        stagew <= 2'b01;
                        state <= WAIT_15MS_AFTER_INIT;
                    end
                    else if(stage == 2'b01) begin 
                        stagew <= 2'b10;
                        state <= WAIT_MEASURE_90MS;
                    end
                    else if(stagew == 2'b10) begin
                        stagew <= 2'b01;
                        state <= IDLE;
                    end
                    busy <= 0;
                    scl_t <= 0;
                end
            end
            WAIT_15MS_AFTER_INIT: begin
                state_send_sen <= 4'b1011;
                if(count_delay < delay_20ms) begin
                    count_delay <= count_delay+1;
                end
                else begin
                    count_delay <= 0;
                    state <= IDLE;
                end
            end
            WAIT_MEASURE_90MS: begin
                state_send_sen <= 4'b1100;
                if(count_delay < delay_200ms) begin
                    count_delay <= count_delay+1;
                end
                else begin
                    count_delay <= 0;
                    state <= IDLE;
                end
            end
        endcase
end
wire [63:0] temp_cal,hum_cal;
assign hum_cal = hum_raw*10000;
assign hum_raw = {data_receive[1],data_receive[2],data_receive[3][7:4]};
assign humidity_vl = hum_cal/SCALE;

assign temp_cal = temp_raw*20000;
assign temp_raw = {data_receive[3][3:0],data_receive[4],data_receive[5]};
assign temp_vl = temp_cal/SCALE-5000;

assign stage = stagew;
endmodule
