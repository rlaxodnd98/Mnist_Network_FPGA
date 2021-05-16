module uart (
    input clk,                        // external clk
    input reset_b,                    // asynchronous reset
    input rx_data,                    // recieved data
    output [3:0] label_out,
    output [783:0] pixel_out,
    output enable,                    // start_train_sw signal
    output tx_data                    // transimtter data
);

parameter D_BIT = 8;
parameter SB_TICK = 16;

wire sampling_tick;                   // sampling_tick 
wire rx_done_tick;                    // recieve done
wire [7:0] d_out;                     // recieved data


///////////////////////////////////////////////
// UART_recieve module
///////////////////////////////////////////////
uart_rx #(.D_BIT(D_BIT), .SB_TICK(SB_TICK)) UART_RX (
	.clk(clk),                        // input:  external clk
	.reset_b(reset_b),                // input:  asynchronous reset
	.rx_data(rx_data),                // input:  recieved data
	.sampling_tick(sampling_tick),    // input:  UART sampling tick(16 times)
	.rx_done_tick(rx_done_tick),      // output: recieve done tick signal
	.d_out(d_out)                     // output: recieved 8bit data
);

//////////////////////////////////////////////
// UART_transmit module
//////////////////////////////////////////////
uart_tx #(.D_BIT(D_BIT), .SB_TICK(SB_TICK)) UART_TX (
    .clk(clk),                        // input:  external clk
    .reset_b(reset_b),                // input:  asynchronous reset
    .tx_start(rx_done_tick),          // input:  transmitter start signal
    .sampling_tick(sampling_tick),    // input:  baud rate generator signal
    .d_in(d_out),                     // input:  8bit data input
    .tx_done_tick(),                  // output: transmit done
    .tx_data(tx_data)                 // output: single bit data
);

/////////////////////////////////////////
// Baud rate generator
/////////////////////////////////////////
clock_frequency_divider #(
    .MOD(163),    // CLK = 25MHz, Baudrate = 9,600
    .N_COUNT_BIT(8)) CLK_DIVIER (
    .clk(clk),
    .reset_b(reset_b),
    .clk_divide(sampling_tick)
);

///////////////////////////////////////////////
// label_out(4bit), pixel_out(784bit) buffer
///////////////////////////////////////////////
buffer #(.ASCIIBIT(8), .COUNT(99)) BUFFER(
    .clk(clk),
    .reset_b(reset_b),
    .data(d_out),
    .receive_done(rx_done_tick), //from receiver
    .label_out(label_out),
    .pixel_out(pixel_out),
    .enable(enable)
);

endmodule
