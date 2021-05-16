module UART_TEST #(
    parameter D_BIT = 8,
    parameter BUFSIZE = 8) (
    input clk,
    input reset,
    input rx_data,
	output [7:0] data,
	output [7:0] com,
    output reg [D_BIT-1:0] data_out
);

display #(.SLOW_CLK(500)) DISPLAY (
    .clk(clk),
    .reset_b(reset_b),              // active high reset
    .Yes(Yes),            // the number of matched data
    .No(No),             // the number of mismatched data
	.data(data),          // 7-segment data displayed
	.com(com)            // location for 7-segment display
);

/* variable for debugging */
reg [13:0] Yes;
reg [13:0] No;


wire reset_b;
wire sampling_tick;  // UART sampling tick
wire rx_done_tick;   // 
wire [D_BIT-1:0] data_packet; 
// reg data_out;


//          Data bit       stop bit tick
uart_rx #(.D_BIT(D_BIT), .SB_TICK(16)) UART_RX (
    .clk(clk),                      // input:  external clk 
    .reset_b(reset_b),              // input:  asynchronous reset
    .rx_data(rx_data),              // input:  recieved data
    .sampling_tick(sampling_tick),  // input:  sampling CLK signal(clk divider)
    .rx_done_tick(rx_done_tick),    // output: complete create data packet
    .d_out(data_packet)             // output: D_BIT data packet
);

// CLK = 5MHz, Baud rate = 9600, Oversampling = 16
// generate 32 CLK -> 1CLK 
clock_frequency_divider #(.MOD(32), .N_COUNT_BIT(5)) CLK_DIVIDER (
    .clk(clk),                      // input:  external clk
    .reset_b(reset_b),              // input:  asynchronous reset
    .clk_divide(sampling_tick)      // output: clk_divider for uart_rx module
);

// if rx_done_tick signal reaches, 
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
	     data_out <= 8'b10011011;
	 end else if (rx_done_tick) begin
        data_out <= data_packet;
    end 
end

// always blocks for debugging
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
	     Yes <= 0;
		  No <= 0;
	 end else begin
	     if (sampling_tick) begin
		      if (rx_data) begin
		          Yes <= Yes + 14'd1;
		      end else begin
		          No <= No + 14'd1;
		      end
		  end
	 end
end
/*
buffer_Nbit #(
	.BUFSIZE(8),
	.D_BIT(8),
	.MAX_COUNT(1)) BUF8 (
    .clk(clk),
    .reset_b(reset_b),
    .rx_done_tick(rx_done_tick),
    .data_in(data_packet),
    .data_done(),  // unused pin
    .data_out(data_out)

);
*/

assign reset_b = !reset;

endmodule 