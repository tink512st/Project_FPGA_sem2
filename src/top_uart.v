module top_uart#(
	parameter clk_freq = 125_000_000,
	parameter baud_rate = 9600
)(donerx,donetx,doutrx,tx,clk,rst,rx,newd,dintx);
output donerx,donetx,tx;
output [7:0] doutrx;
input clk,rst,rx,newd;
input [7:0] dintx;

uarttx #( 					
	.clk_freq(clk_freq),
	.baud_rate(baud_rate)
)
utx(.doneTx(donetx),.tx(tx),.clk(clk),.rst(rst),.new_data(newd),.tx_data(dintx));
uartrx#(
	.clk_freq(clk_freq),
	.baud_rate(baud_rate)
)
urx(.doneRx(donerx),.rxData(doutrx),.clk(clk),.rst(rst),.rx(rx));
endmodule