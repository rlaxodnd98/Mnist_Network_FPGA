module second_layer_cell #(
    parameter NWBITS = 16,
    parameter NHIDDEN = 256,
    parameter COUNT_BIT1=10,
    parameter COUNT_BIT2=8,
    parameter NUM = 0) (       // NUM : initial memory number
    input clk,
    input reset_b,
    input update_second_layer,
    input start_state2,
    input start_backprop,
    input signed [NWBITS+COUNT_BIT1-1:0] hidden_multiply,
    input signed [NWBITS-1:0] delta_weight,
    input signed [NWBITS-1:0] delta_bias,
    output signed [NWBITS+NWBITS+COUNT_BIT2+COUNT_BIT1-1:0] output_neuron,
    output signed [NWBITS-1:0] second_layer_weight,       // weight_out for backprop
    output end_state2,             // state2 end signal
    output end_state4              // state4 end signal
);

/** Used parameter list in top-level module
 *
 *    
parameter NWBITS = 16;       // weight bits 
parameter NHIDDEN = 256;     // number of hidden_neuron
parameter NTEST = 10000;     // number of test vector
parameter NPIXEL = 784;      // 28 * 28 pixel array
parameter COUNT_BIT1 = 10;  // int(log2(NDATA)) + 1
parameter COUNT_BIT2 = 8;   // int(log2(NHIDDEN))
parameter NOUT = 10;         // number of output layer
 */

// signals which will be observed.
wire signed [NWBITS-1:0] second_layer_weight2;
wire en_in_out;
wire start_multiply;              // weighted_sum2 module enable signal 
wire signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] weighted_sum;
wire add_bias;
assign second_layer_weight = second_layer_weight2;

weighted_sum2 #(
    .NWBITS(NWBITS),             // parameter NWBITS
    .NHIDDEN(NHIDDEN),           // parameter NHIDDEN
    .COUNT_BIT1(COUNT_BIT1),                  // parameter COUNT_BIT1
    .COUNT_BIT2(COUNT_BIT2)) MULTI2 (        // parameter COUNT_BIT2
    .clk(clk),                   // input:  external clk
    .reset_b(reset_b),           // input:  asynchronous reset
    .start_multiply(start_multiply),  // input:  enable signal of multiply
    .hidden_multiply(hidden_multiply),   // input:  first layer data(HIDDEN layer)
    .second_layer_weight(second_layer_weight2),  // input:  memory weight data
    .weighted_sum(weighted_sum),          // output: multiply data
    .add_bias(add_bias)    // output: signal for adding is ended
);

weight_memory2 #(
    .NWBITS(NWBITS),             // parameter NWBITS
    .NHIDDEN(NHIDDEN),           // parameter NHIDDEN
    .COUNT_BIT1(COUNT_BIT1),   // parameter COUNT_BIT1
    .COUNT_BIT2(COUNT_BIT2),   // parameter COUNT_BIT2
    .NUM(NUM)) MEM2 (            
    .clk(clk),                   // input:  external clk
    .reset_b(reset_b),           // input:  asynchronous reset
    .update_weight(update_second_layer),  // input:  enable input
    .start_state2(start_state2),      // input:  start getout second_layer_weight
    .start_backprop(start_backprop),  // input:  enable backpropagation
    .delta_weight(delta_weight),     // input:  delta_weight data
    .second_layer_weight(second_layer_weight2),  // output: output weight
    .end_state4(end_state4),       // output: input is ended(for debugging)
    .start_multiply(start_multiply)  // output: signal for output is ended
);

bias2 #(
    .NWBITS(NWBITS),             // parameter NWBITS
    .COUNT_BIT2(COUNT_BIT2),                 // parameter COUNT_BIT2
    .COUNT_BIT1(COUNT_BIT1),
    .NUM(NUM)) BIAS2 (             // parameter COUNT_BIT1
    .clk(clk),                     // input:  external clk
    .reset_b(reset_b),             // input:  asynchronous reset
    .update_bias(update_second_layer),  // input:  enable input(share memory module)
    .add_bias(add_bias),           // input:  enable output(weighted sum output)
    .weighted_sum(weighted_sum),   // input:  multiply result(weighted sum output)
    .delta_bias(delta_bias),       // input:  delta bias data
    .output_neuron(output_neuron), // output: output neuron data
    .end_state2(end_state2)        // output: signal for system is ended
);

endmodule

