module uarttx#( 					// phan #(parameter) dung de truyen tham so khi goi module giup de tai su dung code
	parameter clk_freq = 1000000, //1Mhz
	parameter baud_rate = 9600	// toc do baud 
)
(doneTx,tx,clk,rst,new_data,tx_data);
input clk,rst,new_data;
input [7:0] tx_data;
output reg doneTx, tx;

parameter  idle = 2'b00, start = 2'b01, transfer = 2'b10, stop = 2'b11;
reg [1:0] state; 
localparam clk_count = (clk_freq/baud_rate);

integer count = 0;
integer counts = 0;
reg uclk = 0;

always@(posedge clk) begin
	if(count < clk_count/2)
		count <= count + 1;
	else begin
		count <= 0;
		uclk <= ~uclk;
	end
end

reg [7:0] din;	// bo nho chua du lieu dau vao
always@(posedge uclk) begin
	if(rst) begin
		state <= idle;
		doneTx <= 0;
    end
	else begin
		case(state)
			idle: begin
				counts <= 0;
				tx <= 1;
				doneTx <= 0;
				if(new_data) begin
					state <= transfer;
					tx <= 0;
					din <= tx_data;
				end
				else 
					state <= idle;
			end
			transfer: begin
				if(counts <= 7) begin
					tx <= din[counts];
					counts <= counts + 1;
					state <= transfer;
				end
				else begin
					counts <= 0;
					state <= idle;
					tx <= 1;
					doneTx <= 1;
				end
			end
			default: state <= idle;
		endcase
		
	end
end
endmodule