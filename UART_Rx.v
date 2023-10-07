module uart_receiver(rx_in,rx_clock,rx_reset,rx_parity_bit_error,stop_bit_error,data_out_rx);
input rx_in,rx_clock,rx_reset;
output rx_parity_bit_error,stop_bit_error;
output [7:0]data_out_rx;

wire w_start_detect, w_parity_load, w_shift_rx, w_check_stop;
wire [7:0]w_data;

fsm_rx  f2(.start_detect_rx(w_start_detect),.rx_parity_bit_error(rx_parity_bit_error),.rx_clock(rx_clock),
    .rx_reset(rx_reset),.parity_load_rx(w_parity_load),.rx_shift(w_shift_rx),.check_stop_rx(w_check_stop));
sipo_rx  sp2(.rx_data_in(rx_in),.rx_clock(rx_clock),.rx_reset(rx_reset),.rx_shift(w_shift_rx),.rx_out(w_data));
start_bit_detector  sbd2(.rx_data_in(rx_in),.start_detect_rx(w_start_detect));
stop_bit_detector  stopbd2(.rx_data_in(rx_in),.check_stop_rx(w_check_stop),.stop_bit_error(stop_bit_error));
parity_checker  pc2(.rx_data_in(rx_in),.parity_load_rx(w_parity_load),.data_in_sipo(w_data),.rx_parity_bit_error(rx_parity_bit_error));

assign data_out_rx = (stop_bit_error == 0) ? w_data : 8'bz;

endmodule


module sipo_rx(rx_data_in,rx_clock,rx_reset,rx_shift,rx_out);
input rx_clock,rx_reset;
input rx_shift;
input rx_data_in;
output [7:0]rx_out;

reg [7:0]temp_rx;

always @(posedge rx_clock, negedge rx_reset)
begin
if(!rx_reset)
temp_rx <= 8'bx;
else if(rx_shift)
temp_rx <= {rx_data_in,temp_rx[7:1]};
end

assign rx_out = (!rx_shift) ? temp_rx : rx_out;

endmodule

module start_bit_detector(rx_data_in,start_detect_rx);
input rx_data_in;
output reg start_detect_rx;

always @(rx_data_in)
begin
if(rx_data_in == 0)
start_detect_rx = 1;
else 
start_detect_rx = 0;
end

endmodule

module stop_bit_detector(rx_data_in,check_stop_rx,stop_bit_error);
input rx_data_in, check_stop_rx;
output reg stop_bit_error;

always @(rx_data_in,check_stop_rx)
begin
if(check_stop_rx)
begin
    if(rx_data_in==1)
    stop_bit_error = 0;
    else
    stop_bit_error = 1;
end
end
endmodule

module parity_checker(rx_data_in,parity_load_rx,data_in_sipo,rx_parity_bit_error);
input rx_data_in,parity_load_rx;
input [7:0] data_in_sipo;
output reg rx_parity_bit_error;

always @(rx_data_in, data_in_sipo, parity_load_rx)
begin
if(parity_load_rx == 1)
begin
    if(rx_data_in == ^data_in_sipo)
    rx_parity_bit_error = 0;
    else
    rx_parity_bit_error = 1;
end
end

endmodule


module fsm_rx(start_detect_rx,rx_parity_bit_error,rx_clock,rx_reset,parity_load_rx,rx_shift,check_stop_rx);
input rx_clock,rx_reset;
input start_detect_rx, rx_parity_bit_error;
output reg check_stop_rx, rx_shift, parity_load_rx;

parameter [1:0] IDLE_RX = 2'b00, DATA_RX = 2'b01, PARITY_BIT_RX = 2'b10, STOP_RX = 2'b11;

reg [1:0] state_rx, next_state_rx;
integer count_rx =1;
reg go_rx;

always @(posedge rx_clock)  begin
if(go_rx == 1)
count_rx <= count_rx + 1;
else
count_rx <= 1;
end

always @(state_rx, start_detect_rx, rx_parity_bit_error,count_rx)
begin
case(state_rx)
IDLE_RX : next_state_rx = (start_detect_rx) ? DATA_RX : IDLE_RX;
DATA_RX : begin
    go_rx = (count_rx == 8) ? 0 : 1;
    next_state_rx = (count_rx == 8) ? PARITY_BIT_RX : DATA_RX;
end
PARITY_BIT_RX : next_state_rx = (rx_parity_bit_error == 1) ? IDLE_RX : STOP_RX;
STOP_RX : next_state_rx = IDLE_RX;
default :  next_state_rx = IDLE_RX;
endcase
end


always @(posedge rx_clock, negedge rx_reset)
begin
if(!rx_reset)
state_rx <= IDLE_RX;
else
state_rx <= next_state_rx;
end


always @(state_rx)
begin
if(state_rx == IDLE_RX)
begin
rx_shift = 0;
parity_load_rx = 0;
check_stop_rx = 0;
end
else if(state_rx == DATA_RX)
begin
rx_shift = 1;
parity_load_rx = 0;
check_stop_rx = 0;
end
else if(state_rx == PARITY_BIT_RX)
begin
rx_shift = 0;
parity_load_rx = 1;
check_stop_rx = 0;
end
else if(state_rx == STOP_RX)
begin
rx_shift = 0;
parity_load_rx = 0;
check_stop_rx = 1;
end
else
begin
rx_shift = 0;
parity_load_rx = 0;
check_stop_rx = 0;
end
end

endmodule
