module uart_transmitter(tx_start,clock_tx,reset_tx,data_out_tx,data_in_tx);
input [7:0]data_in_tx;
input clock_tx,reset_tx;
input tx_start;
output data_out_tx;
wire w_shift_tx,w_load_tx,w_data_bit_tx,w_parity_bit_tx;
wire [1:0] w_select_tx;

fsm_tx  f1(.clock_tx(clock_tx),.reset_tx(reset_tx),.tx_start(tx_start),.shift_tx(w_shift_tx),
            .load_tx(w_load_tx),.select_tx(w_select_tx));
piso_tx  p1(.clock_tx,.reset_tx(reset_tx),.data_in_tx(data_in_tx),.data_out_tx(w_data_bit_tx),
            .load_tx(w_load_tx),.shift_tx(w_shift_tx));
mux_tx  m1(.data_bit_tx(w_data_bit_tx),.parity_bit_tx(w_parity_bit_tx),.data_output_tx(data_out_tx),
            .select_tx(w_select_tx));
parity_generator_tx  pg1(.parity_out_tx(w_parity_bit_tx),.data_in_tx(data_in_tx),.load_tx(w_load_tx));

endmodule




module piso_tx(clock_tx,reset_tx,data_in_tx,data_out_tx,load_tx,shift_tx);
input [7:0]data_in_tx;
input clock_tx,reset_tx;
input load_tx,shift_tx;
output data_out_tx;

reg [7:0]temp_tx;

always @(posedge clock_tx, negedge reset_tx)
begin
if(!reset_tx)
temp_tx <= 8'b0;
else if(load_tx)
temp_tx <= data_in_tx;
else if(shift_tx)
temp_tx <= {1'b0, temp_tx[7:1]};
end

assign data_out_tx = temp_tx[0];

endmodule


module mux_tx(data_bit_tx,parity_bit_tx,data_output_tx,select_tx);
input [1:0]select_tx;
input data_bit_tx,parity_bit_tx;
output reg data_output_tx;

always @(select_tx,data_bit_tx,parity_bit_tx)
begin
case(select_tx)
2'b00 : data_output_tx = 1'b0;
2'b01 : data_output_tx = data_bit_tx;
2'b10 : data_output_tx = parity_bit_tx;
2'b11 : data_output_tx = 1'b1;
default : data_output_tx = 1'b1;
endcase
end

endmodule

module parity_generator_tx(parity_out_tx,data_in_tx,load_tx);
input [7:0]data_in_tx;
input load_tx;
output reg parity_out_tx;
reg [7:0]temp_parity_tx;

always @(load_tx,data_in_tx)
begin
if(load_tx)
temp_parity_tx = data_in_tx;
else
parity_out_tx = ^(temp_parity_tx);
end

endmodule


module fsm_tx(clock_tx,reset_tx,tx_start,shift_tx,load_tx,select_tx);
input clock_tx,reset_tx;
input tx_start;
output reg [1:0]select_tx;
output reg shift_tx,load_tx;

parameter  [2:0] IDLE_TX = 3'b000, START_BIT_TX = 3'b001, DATA_BIT_TX = 3'b010, PARITY_BIT_TX = 3'b011,
                     STOP_BIT_TX = 3'b100;

reg [2:0] state_tx,next_state_tx;
integer count_tx = 1;
reg go_tx;

always @(posedge clock_tx)
begin
if(go_tx)
count_tx <= count_tx + 1;
else
count_tx <= 1;
end

always @(state_tx,tx_start,count_tx)
begin
case(state_tx)
IDLE_TX : next_state_tx = tx_start ? START_BIT_TX : IDLE_TX;
START_BIT_TX : next_state_tx = DATA_BIT_TX;
DATA_BIT_TX : begin
    go_tx = (count_tx == 8) ? 0 : 1;
    next_state_tx = (count_tx == 8) ? PARITY_BIT_TX : DATA_BIT_TX;
end
PARITY_BIT_TX : next_state_tx = STOP_BIT_TX;
STOP_BIT_TX : next_state_tx = IDLE_TX;
default : next_state_tx = IDLE_TX;
endcase 
end

always @(posedge clock_tx, negedge reset_tx)
begin
    if(!reset_tx)
    state_tx <= IDLE_TX;
    else
    state_tx <= next_state_tx;
end

always @(state_tx)
begin
if(state_tx == IDLE_TX)
begin
    select_tx = 2'b11;
    shift_tx = 0;
    load_tx = 0;
end
else if(state_tx == START_BIT_TX)
begin
    select_tx = 2'b00;
    shift_tx = 0;
    load_tx = 1;
end
else if(state_tx == DATA_BIT_TX)
begin
    select_tx = 2'b01;
    shift_tx = 1;
    load_tx = 0;
end
else if(state_tx == PARITY_BIT_TX)
begin
    select_tx = 2'b10;
    shift_tx = 0;
    load_tx = 0;
end
else if(state_tx == STOP_BIT_TX)
begin
    select_tx = 2'b11;
    shift_tx = 0;
    load_tx = 0;
end
else
begin
    select_tx = 2'b11;
    shift_tx = 0;
    load_tx = 0;
end
end
endmodule
