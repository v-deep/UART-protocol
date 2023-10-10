module uart_transmitter_tb;
reg [7:0]data_in_tx;
reg clock_tx = 0,reset_tx;
reg tx_start;
wire data_out_tx;

uart_transmitter  ut1(tx_start,clock_tx,reset_tx,data_out_tx,data_in_tx);

always #5 clock_tx = ~clock_tx;
initial
begin
    reset_tx = 0; data_in_tx = 8'b1011_0011; tx_start = 1;
    #3 reset_tx = 1;
    #117 tx_start = 0;
end

endmodule
