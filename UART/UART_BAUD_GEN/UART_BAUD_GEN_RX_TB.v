module baud_generate_rx_tb;

reg clock=0;
reg [1:0]rx_sel;
wire baud_rx_out;

baud_generate_rx bt1(clock, rx_sel, baud_rx_out);

initial
forever #62.5 clock=~clock; //because time period of 8mhz clock is 125 Therefore we need to toggle our clock at 62.5

initial
rx_sel = 2'b11;

endmodule