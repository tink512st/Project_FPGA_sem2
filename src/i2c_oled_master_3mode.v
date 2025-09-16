module i2c_oled_master(
    done,
    ack_err,
    busy,
    clk,
    rst,
    op,
    newd,
    waddr,
    din,
    dout,
    num_byte_send,
    num_byte_read,
    state_i2c,
    done_write,
    sda_o,
    sda_i,
    sda_t,
    scl_t
);
input clk,rst,newd,op;
input [6:0] waddr;
input [7:0] din;
input [4:0] num_byte_send,num_byte_read;
output reg [7:0] dout;
output reg done, ack_err, busy;
output [3:0] state_i2c;
output reg done_write;

output reg  sda_o;   // dữ liệu xuất (chỉ khi kéo xuống)
input sda_i;       // dữ liệu đọc từ SDA
output reg  sda_t;   // 1 = High-Z, 0 = drive
output reg  scl_t = 0;
parameter sys_freq = 125_000_000;//125Mhz = 125_000_000
parameter i2c_freq = 400_000;//400khz = 400_000
parameter clk_count4 = sys_freq / i2c_freq;
parameter clk_count1 = clk_count4/4;

// --- IOBUF cho SDA ---
//reg  sda_o = 0;   // dữ liệu xuất (chỉ khi kéo xuống)
//wire sda_i;       // dữ liệu đọc từ SDA
//reg  sda_t = 1;   // 1 = High-Z, 0 = drive
//reg  scl_t = 0;

//assign sda = (sda_t == 1'b0 & sda_o == 1'b0) ? 1'b0 :(sda_t == 1'b1) ? 1'b1 : 1'bz;
//assign sda_i = sda;

//IOBUF sda_iobuf (
//    .I(sda_o),  // data output
//    .O(sda_i),  // data input
//    .T(sda_t),  // 1 = High-Z, 0 = drive
//    .IO(sda)    // pin vật lý
//);

// ----------------------------------------------------
reg [1:0] pulse;
integer count1 = 0;
reg [4:0] count_byte1 = 0;
reg [4:0] count_byte2 = 0;
reg [4:0] num_byte_send_m = 0;
reg [4:0] num_byte_read_m = 0;
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

parameter IDLE = 4'd0, 
          START = 4'd1, 
          WRITE_ADD = 4'd2, 
          ACK_1 = 4'd3, 
          WRITE_DATA = 4'd4, 
          ACK = 4'd5, 
          STOP = 4'd8, 
          MASTER_NACK = 4'd9,
          READ_DATA = 4'd10,
          MASTER_ACK = 4'd11;
reg[3:0] state = IDLE;
reg [7:0]tx_data = 0,rx_data = 0;
reg [7:0] add = 0;
reg r_ack = 0;
reg [3:0] bit_count;

always@(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        bit_count <= 0;
        count_byte1 <= 0;
        count_byte2 <= 0;
        sda_t <= 1;   // nhả SDA
        sda_o <= 0;
        scl_t <= 1;
        tx_data <= 0;
        add <= 0;
        ack_err <= 0;
        busy <= 0;
        done <= 0;
        add <= 0;
    end
    else 
       case(state) 
            IDLE: begin
                done <= 0;
                done_write <= 0;
                if(newd) begin
                    state <= START;
                    add <= {waddr,op};
                    busy <= 1;
                    ack_err <= 0;
                end
                else begin
                    tx_data <= 0;
                    add <= 0;
                    busy <= 0;
                    ack_err <= 0;
                end
            end
            START: begin
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
                        bit_count <= 0;
                        tx_data <= din;
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
                    count_byte1 <= count_byte1 + 1;
                    state <= ACK;
                    bit_count <= 0;
                    sda_t <= 1;
//                    sda_o <= 0; sda_t <= 0;
                    done_write <= 1;
                end
            end
            ACK: begin
                sda_t <= 1;
//                sda_o <= 0; sda_t <= 0;
                case(pulse) 
                    0,1: scl_t <= 0;
                    2: begin scl_t <= 1; r_ack <= sda_i; end
                    3: scl_t <= 1;
                endcase
                if(count1 == clk_count1*4-1) begin
                    if(r_ack == 0) begin
                        if(count_byte1 >= num_byte_send_m) begin
                            state <= STOP;
                            count_byte1 <= 0;
                        end
                        else 
                            state <= WRITE_DATA;
                        bit_count <= 0;
                        done_write <= 0;
                        tx_data <= din;
                    end
                    else begin
                        state <= STOP;
                        ack_err <= 1;
                    end
                end
            end
            READ_DATA: begin
                sda_t <= 1;
                if(bit_count <= 7) begin
                    case(pulse) 
                        0,1: scl_t <= 0;
                        2: begin 
                            scl_t <= 1;
                            if(count1 == clk_count1*2 + clk_count1/2)
                                rx_data <= {rx_data[6:0],sda_i};
                        end
                        3: scl_t <= 1;
                    endcase
                    if(count1 == clk_count1*4-1) begin
                        bit_count <= bit_count + 1;
                        scl_t <= 0;
                        dout <= rx_data;
                    end
                end
                else begin
                    count_byte2 <= count_byte2 + 1;
                    bit_count <= 0;
                    if(count_byte2 < num_byte_send-1) 
                        state <= MASTER_ACK;
                    else begin
                        state <= MASTER_NACK;
                        count_byte2 <= 0;
                    end
                end
            end
            MASTER_ACK: begin
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
                sda_t <= 1;
                case(pulse) 
                    0,1,2,3: begin sda_t <= 1; scl_t <= (pulse>=2)?1:0; end
                endcase
                if(count1== clk_count1*4-1) begin
                    scl_t <= 1;
                    sda_t <= 0; sda_o <= 0;
                    state <= STOP;
                end
            end
            STOP: begin
                case(pulse) 
                    0: begin scl_t <= 0; sda_t <= 0; sda_o <= 0; end
                    1: begin scl_t <= 1; sda_t <= 0; sda_o <= 0; end
                    2,3: begin scl_t <= 1; sda_t <= 1; end
                endcase
                if(count1== clk_count1*4-1) begin      
                    busy <= 0;
                    scl_t <= 0;
                    state <= IDLE;   
                    done <= 1;          
                end
            end
        endcase
end
always@(posedge clk, posedge rst) begin
    if(rst) begin
        num_byte_send_m <= 0;
        num_byte_read_m <= 0;
    end
    else begin
        num_byte_send_m <= num_byte_send;
        num_byte_read_m <= num_byte_read;
    end
end
assign state_i2c = state;
endmodule

//module i2c_oled_master(
//    sda,
//    scl,
//    done,
//    ack_err,
//    busy,
//    clk,
//    rst,
//    op,
//    newd,
//    waddr,
//    din,
//    dout,
//    num_byte_send,
//    num_byte_read,
//    state_i2c,
//    done_write
//);
//input clk,rst,newd,op;
//input [6:0] waddr;
//input [7:0] din;
//input [4:0] num_byte_send,num_byte_read;
//inout sda;
//output reg [7:0] dout;
//output reg done, ack_err, busy;
//output scl;
//output [3:0] state_i2c;
//output reg done_write;
//parameter sys_freq = 125_000_000;//125Mhz = 125_000_000
//parameter i2c_freq = 400_000;//400khz = 400_000
//parameter clk_count4 = sys_freq / i2c_freq;
//parameter clk_count1 = clk_count4/4;

//// --- IOBUF cho SDA ---
//reg  sda_o = 0;   // dữ liệu xuất (chỉ khi kéo xuống)
//wire sda_i;       // dữ liệu đọc từ SDA
//reg  sda_t = 1;   // 1 = High-Z, 0 = drive
//reg  scl_t = 0;
////assign sda = (sda_t == 1'b0 & sda_o == 1'b0) ? 1'b0 :(sda_t == 1'b1) ? 1'b1 : 1'bz;
////assign sda_i = sda;
//IOBUF sda_iobuf (
//    .I(sda_o),  // data output
//    .O(sda_i),  // data input
//    .T(sda_t),  // 1 = High-Z, 0 = drive
//    .IO(sda)    // pin vật lý
//);

//// ----------------------------------------------------
//reg [1:0] pulse;
//integer count1 = 0;
//reg [4:0] count_byte1 = 0;
//reg [4:0] count_byte2 = 0;
//reg [4:0] num_byte_send_m = 0;
//reg [4:0] num_byte_read_m = 0;
//// Tạo trạng thái xung
//always @(posedge clk) begin
//    if(rst) begin
//        pulse <= 0;
//        count1 <= 0;
//    end
//    else if(busy == 0) begin
//        pulse <= 0;
//        count1 <= 0;
//    end
//    else if(count1 == clk_count1-1) begin
//        pulse <= 1;
//        count1 <= count1+1;
//    end
//    else if(count1 == clk_count1*2-1) begin
//        pulse <= 2;
//        count1 <= count1+1;
//    end
//    else if(count1 == clk_count1*3-1) begin
//        pulse <= 3;
//        count1 <= count1+1;
//    end
//    else if(count1 == clk_count1*4-1) begin
//        pulse <= 0;
//        count1 <= 0;
//    end
//    else begin
//        count1 <= count1 + 1;
//    end
//end

//parameter IDLE = 4'd0, 
//          START = 4'd1, 
//          WRITE_ADD = 4'd2, 
//          ACK_1 = 4'd3, 
//          WRITE_DATA = 4'd4, 
//          ACK = 4'd5, 
//          STOP = 4'd8, 
//          MASTER_NACK = 4'd9,
//          READ_DATA = 4'd10,
//          MASTER_ACK = 4'd11;
//reg[3:0] state = IDLE;
//reg [7:0]tx_data = 0,rx_data = 0;
//reg [7:0] add = 0;
//reg r_ack = 0;
//reg [3:0] bit_count;

//always@(posedge clk or posedge rst) begin
//    if(rst) begin
//        state <= IDLE;
//        bit_count <= 0;
//        count_byte1 <= 0;
//        count_byte2 <= 0;
//        sda_t <= 1;   // nhả SDA
//        sda_o <= 0;
//        scl_t <= 1;
//        tx_data <= 0;
//        add <= 0;
//        ack_err <= 0;
//        busy <= 0;
//        done <= 0;
//        add <= 0;
//    end
//    else 
//       case(state) 
//            IDLE: begin
//                done <= 0;
//                done_write <= 0;
//                if(newd) begin
//                    state <= START;
//                    add <= {waddr,op};
//                    busy <= 1;
//                    ack_err <= 0;
//                end
//                else begin
//                    tx_data <= 0;
//                    add <= 0;
//                    busy <= 0;
//                    ack_err <= 0;
//                end
//            end
//            START: begin
//                case(pulse)
//                    0,1: begin sda_t <= 1; scl_t <= 1; end 
//                    2,3: begin sda_t <= 0; sda_o <= 0; scl_t <= 1; end 
//                endcase
//                if(count1 == clk_count1*4-1) begin
//                    state <= WRITE_ADD;
//                    scl_t <= 0;
//                end
//            end
//            WRITE_ADD: begin
//                if(bit_count<=7) begin
//                    case(pulse) 
//                        0: begin scl_t <= 0; end
//                        1: begin scl_t <= 0;
//                            if(add[7-bit_count]==1'b0) begin sda_t <= 0; sda_o <= 0; end
//                            else sda_t <= 1;
//                        end
//                        2,3: begin scl_t <= 1; end
//                    endcase
//                    if(count1 == clk_count1*4-1) begin
//                        bit_count <= bit_count + 1;
//                        scl_t <= 0;
//                    end
//                end
//                else begin
//                    bit_count <= 0;
//                    state <= ACK_1;
//                    scl_t <= 0;
//                    sda_t <= 1; 
////                    sda_o <= 0; sda_t <= 0;
//                end
//            end
//            ACK_1: begin
//                sda_t <= 1;
////                sda_o <= 0; sda_t <= 0;
//                case(pulse) 
//                    0,1: scl_t <= 0;
//                    2: begin scl_t <= 1; r_ack <= sda_i; end
//                    3: scl_t <= 1;
//                endcase
//                if(count1 == clk_count1*4-1) begin
//                    if(r_ack == 0 && add[0] == 0) begin
//                        state <= WRITE_DATA;
//                        bit_count <= 0;
//                        tx_data <= din;
//                    end
//                    else if(r_ack == 0 && add[0] == 1) begin
//                        state <= READ_DATA;
//                        bit_count <= 0;
//                    end
//                    else begin
//                        state <= STOP;
//                        ack_err <= 1;
//                    end
//                end
//            end
//            WRITE_DATA: begin
//                if(bit_count <= 7) begin
//                    case(pulse) 
//                        0: scl_t <= 0;
//                        1: begin scl_t <= 0;
//                            if(tx_data[7-bit_count]==1'b0) begin sda_t <= 0; sda_o <= 0; end
//                            else sda_t <= 1;
//                        end
//                        2,3: scl_t <= 1;
//                    endcase
//                    if(count1 == clk_count1*4-1) begin
//                        bit_count <= bit_count + 1;
//                        scl_t <= 0;
//                    end
//                end
//                else begin
//                    count_byte1 <= count_byte1 + 1;
//                    state <= ACK;
//                    bit_count <= 0;
//                    sda_t <= 1;
////                    sda_o <= 0; sda_t <= 0;
//                    done_write <= 1;
//                end
//            end
//            ACK: begin
//                sda_t <= 1;
////                sda_o <= 0; sda_t <= 0;
//                case(pulse) 
//                    0,1: scl_t <= 0;
//                    2: begin scl_t <= 1; r_ack <= sda_i; end
//                    3: scl_t <= 1;
//                endcase
//                if(count1 == clk_count1*4-1) begin
//                    if(r_ack == 0) begin
//                        if(count_byte1 >= num_byte_send_m) begin
//                            state <= STOP;
//                            count_byte1 <= 0;
//                        end
//                        else 
//                            state <= WRITE_DATA;
//                        bit_count <= 0;
//                        done_write <= 0;
//                        tx_data <= din;
//                    end
//                    else begin
//                        state <= STOP;
//                        ack_err <= 1;
//                    end
//                end
//            end
//            READ_DATA: begin
//                sda_t <= 1;
//                if(bit_count <= 7) begin
//                    case(pulse) 
//                        0,1: scl_t <= 0;
//                        2: begin 
//                            scl_t <= 1;
//                            if(count1 == clk_count1*2 + clk_count1/2)
//                                rx_data <= {rx_data[6:0],sda_i};
//                        end
//                        3: scl_t <= 1;
//                    endcase
//                    if(count1 == clk_count1*4-1) begin
//                        bit_count <= bit_count + 1;
//                        scl_t <= 0;
//                        dout <= rx_data;
//                    end
//                end
//                else begin
//                    count_byte2 <= count_byte2 + 1;
//                    bit_count <= 0;
//                    if(count_byte2 < num_byte_send-1) 
//                        state <= MASTER_ACK;
//                    else begin
//                        state <= MASTER_NACK;
//                        count_byte2 <= 0;
//                    end
//                end
//            end
//            MASTER_ACK: begin
//                case(pulse)
//                    0: begin scl_t <= 0; sda_t <= 0; sda_o <= 0; end
//                    1: scl_t <= 0;
//                    2: scl_t <= 1;
//                    3: scl_t <= 1;
//                endcase
//                if(count1 == clk_count1*4-1) begin
//                    state <= READ_DATA;
//                    sda_t <= 1;
//                    scl_t <= 0;
//                end
//            end
//            MASTER_NACK: begin
//                sda_t <= 1;
//                case(pulse) 
//                    0,1,2,3: begin sda_t <= 1; scl_t <= (pulse>=2)?1:0; end
//                endcase
//                if(count1== clk_count1*4-1) begin
//                    scl_t <= 1;
//                    sda_t <= 0; sda_o <= 0;
//                    state <= STOP;
//                end
//            end
//            STOP: begin
//                case(pulse) 
//                    0: begin scl_t <= 0; sda_t <= 0; sda_o <= 0; end
//                    1: begin scl_t <= 1; sda_t <= 0; sda_o <= 0; end
//                    2,3: begin scl_t <= 1; sda_t <= 1; end
//                endcase
//                if(count1== clk_count1*4-1) begin      
//                    busy <= 0;
//                    scl_t <= 0;
//                    state <= IDLE;   
//                    done <= 1;          
//                end
//            end
//        endcase
//end
//always@(posedge clk, posedge rst) begin
//    if(rst) begin
//        num_byte_send_m <= 0;
//        num_byte_read_m <= 0;
//    end
//    else begin
//        num_byte_send_m <= num_byte_send;
//        num_byte_read_m <= num_byte_read;
//    end
//end
//assign scl = scl_t;
//assign state_i2c = state;
//endmodule
