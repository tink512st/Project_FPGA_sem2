module button_debounced_fsm (
    input wire clk,
    input wire rst,
    input wire btn_in,
    output reg [1:0] mode
);
    parameter max_count = 200000; // 10ms @ 100MHz clock : 100000
    parameter WIDTH = 20;
    reg [3:0] count_reg;
    //debounce cho nut tang
    reg btn_pressed_pulse,btn_in_sync1,btn_in_sync2;
    parameter 
        IDLE       = 2'b00,
        WAIT_STABLE = 2'b01,
        PULSE      = 2'b10,
        WAIT_RELEASE = 2'b11;

    reg[1:0] state;
    integer count;
    always@(posedge clk) begin
        btn_in_sync1<=btn_in;
        btn_in_sync2 <= btn_in_sync1;
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            btn_pressed_pulse <= 0;
        end else begin
            case (state)
                IDLE: begin
                count <= 0;
                    btn_pressed_pulse <= 0;
                    if (btn_in_sync2) begin
                        state <= WAIT_STABLE;
                        count <= 1;
                    end
                end
                WAIT_STABLE: begin
                    if (btn_in_sync2) begin
                        count <= count + 1;
                        if (count >= max_count) begin
                            state <= PULSE;
                        end
                    end else begin
                        state <= IDLE;
                        count <= 0;
                    end
                end
                PULSE: begin
                    btn_pressed_pulse <= 1; // chỉ đúng 1 chu kỳ
                    state <= WAIT_RELEASE;
                end
                WAIT_RELEASE: begin
                    btn_pressed_pulse <= 0;
                    if (!btn_in_sync2) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
always@(posedge clk, posedge rst) begin
    if(rst)
        mode <= 2'd0;
    else if(btn_pressed_pulse == 1)
        case(mode)
            0: mode <= 2'd1;
            1: mode <= 2'd2;
            2: mode <= 2'd0;
            default : mode <= 2'd0;
        endcase
end
endmodule
