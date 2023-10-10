module baud_generate_tx_tb;

reg clock=0;
reg [1:0]tx_sel;
wire baud_tx_out;

baud_generate_tx bt1(clock, tx_sel, baud_tx_out);

initial
forever #50 clock=~clock;

initial
tx_sel = 2'b11;

endmodule