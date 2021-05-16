module Neural_Network_Synthesis #(
    parameter NWBITS = 16,             // weight bits 
    parameter NHIDDEN = 256,           // number of hidden neuron
    parameter NPIXEL = 784,            // 28 * 28 data array
    parameter COUNT_BIT1 = 10,         // int(log2(NPIXEL)) + 1
    parameter COUNT_BIT2 = 8,          // int(log2(NHIDDEN)) 
    parameter NOUT = 10,               // number of output neuron
    parameter NHBITS = NWBITS + COUNT_BIT1,    // number of hidden_neuron bits
    parameter OUT_BIT = NHBITS + NWBITS + COUNT_BIT2) (  // output_neuron bit
    //input clk_in1_p,             // clk 100MHz
    //input clk_in1_n,             // clk 100MHz
    input clk,
	 input reset,               // active high reset
	input rx_data,             // uart input 
	output reg [3:0] led,     // debugging LED
	output reg [1:0] ledA,    // debugging LED
    output reg [3:0] ledB,    // debugging LED
    output tx_data            // uart output
);

/* Neural Network data of matched and mismatched */
wire [13:0] Yes;      // number of matched
wire [13:0] No;       // number of mismatched

/* internal variable*/
wire [NPIXEL-1:0] pixel;  
wire [3:0] target_label;
wire start_train_sw;   // start_train signal for Neural_Network module
wire end_system;       // Neural_Network ends 1 training

/* clk signal*/

// reset_b signal
wire reset_b;
assign reset_b = ~reset;


/* always block for ledA signal */
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        ledA <= 2'b11;	 
	end else begin
        if (start_train_sw) ledA[0] <= 1'b0;
		if (end_system) ledA[1] <= 1'b0;
	end
end

/* always block for led signal */
always @(*) begin
    if (Yes + No < 14'd10) begin
        led = 4'd0;
    end else if (Yes + No < 14'd20) begin
        led = 4'd1;
    end else if (Yes + No < 14'd30) begin
        led = 4'd2;
    end else if (Yes + No < 14'd40) begin
        led = 4'd3;
    end else if (Yes + No < 14'd50) begin
        led = 4'd4;
    end else if (Yes + No < 14'd60) begin
        led = 4'd5;
    end else if (Yes + No < 14'd70) begin
        led = 4'd6;
    end else if (Yes + No < 14'd80) begin
        led = 4'd7;
    end else if (Yes + No < 14'd90) begin
        led = 4'd8;
    end else if (Yes + No < 14'd100) begin
        led = 4'd9;
    end else if (Yes + No < 14'd110) begin
        led = 4'd10;
    end else if (Yes + No < 14'd120) begin
        led = 4'd11;
    end else if (Yes + No < 14'd130) begin
        led = 4'd12;
    end else if (Yes + No < 14'd140) begin
        led = 4'd13;
    end else if (Yes + No < 14'd150) begin
        led = 4'd14;
    end else begin
        led = 4'd15;
    end
end

always @(*) begin
    if (Yes + No > 14'd1000) begin
        ledB = 4'd0;
    end else if (Yes + No > 14'd2000) begin
        ledB = 4'd1;
    end else if (Yes + No > 14'd3000) begin
        ledB = 4'd2;
    end else if (Yes + No > 14'd4000) begin
        ledB = 4'd3;
    end else if (Yes + No > 14'd5000) begin
        ledB = 4'd4;
    end else if (Yes + No > 14'd6000) begin
        ledB = 4'd5;
    end else if (Yes + No > 14'd7000) begin
        ledB = 4'd6;
    end else begin
        ledB = 4'd7;
    end 
end




/////////////////////////////////////////////
///  UART_rx module for Neural_Network
/////////////////////////////////////////////
uart UART(
    .clk(clk),                  // input:  external clk
    .reset_b(reset_b),          // input:  asynchronous reset
    .rx_data(rx_data),          // input:  uart_data input
    .label_out(target_label),   // output: target_label for Neural_Network
    .pixel_out(pixel),          // output: 784bit pixel
    .enable(start_train_sw),    // output: start_train switch
    .tx_data(tx_data)           // output: uart_data output
);


Neural_Network #(
    .NWBITS(NWBITS),       
    .NHIDDEN(NHIDDEN),
    .NPIXEL(NPIXEL),
    .COUNT_BIT1(COUNT_BIT1),
    .COUNT_BIT2(COUNT_BIT2),
    .NOUT(NOUT),
    .NHBITS(NHBITS),
    .OUT_BIT(OUT_BIT)) NEURAL_NETWORK (
    .clk(clk),
    .reset_b(reset_b),
    .start_train_sw(start_train_sw),
    .pixel(pixel),                  // currently 784 number of pixel
    .target_label(target_label),    // pixel label data(0~9)
    .end_system(end_system),        
    .Yes(Yes),
    .No(No)
);

/* UN-USED BLOCK
////////////////////////////////////////////
// DISPLAY module for ALTREA HBE-COMBO2
////////////////////////////////////////////
display #(.SLOW_CLK(500)) Display (
    .clk(clk),
    .reset_b(reset_b),
    .Yes(Yes),
    .No(No),
	.data(display_data),
	.com(display_com)
);
*/

endmodule 

/////////////////////////////////////////////////////////
// clk_divider 
////////////////////////////////////////////////////////



/* 
// debouncing module
module debounce(
    input pb_1,
    input clk, 
    output pb_out
);

wire Q1,Q2,Q2_bar,Q0;
my_dff d0(clk, pb_1, Q0);

my_dff d1(clk, Q0, Q1);
my_dff d2(clk, Q1, Q2);
assign Q2_bar = ~ Q2;
assign pb_out = Q1 & Q2_bar;

endmodule


// D-flipflop for debouncing module 
module my_dff(
    input clk,
    input D, 
    output reg Q
);

always @ (posedge clk) begin
    Q <= D;
end

endmodule
*/