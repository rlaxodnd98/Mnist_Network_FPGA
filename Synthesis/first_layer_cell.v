module first_layer_cell #(
    parameter NWBITS = 16,           // weight bits
    parameter NPIXEL = 784,          // number of pixel
    parameter COUNT_BIT1 = 10,      
    parameter NUM = 0) (             // memory initialization number
    input clk,
    input reset_b,
    input update_first_layer,        // change bias and weight signal(1clk period)
    input start_state1,              // calculate weighted sum(1clk period)
    input pixel_multiply,            // 1bit pixel data
    input signed [NWBITS-1:0] delta_weight,            
    input signed [NWBITS-1:0] delta_bias,
    output signed [NWBITS+COUNT_BIT1-1:0] hidden_neuron,  // next_layer data 
    output end_state1,                                    // finish state1
    output end_state6                                     // finish state6
);


// signals which will be observed.
wire add_bias;                                     // start adding bias signal
wire start_multiply;                               // input of weighted_sum
wire signed [NWBITS+COUNT_BIT1-1:0] weighted_sum;  // output for multiply10 module
wire signed [NWBITS-1:0] first_layer_weight;       // output of weight_memory
wire signed [NWBITS+COUNT_BIT1-1:0] before_relu;

assign hidden_neuron = (before_relu > 0) ? before_relu : 26'sd0;

// Instantiaion of the design
// I/O pins connects with signals above variable
weighted_sum1 #(
    .NWBITS(NWBITS),            
    .NPIXEL(NPIXEL), 
    .COUNT_BIT1(COUNT_BIT1)) WEIGHTED_SUM1 ( 
    .clk(clk),                                // input:  external clk
    .reset_b(reset_b),                        // input:  asynchronous reset
    .start_multiply(start_multiply),          // input: start multiply
    .pixel_multiply(pixel_multiply),          // input: pixel data
    .first_layer_weight(first_layer_weight),  // input:  first_layer_weight data
    .weighted_sum(weighted_sum),              // output: weighted sum 
    .add_bias(add_bias)                       // output: signal for multiply ended.
);

weight_memory1 #(
    .NWBITS(NWBITS), 
    .NPIXEL(NPIXEL), 
    .COUNT_BIT1(COUNT_BIT1), 
    .NUM(NUM)) MEM1 (
    .clk(clk),                               // input:  external clk
    .reset_b(reset_b),                       // input:  asynchronous reset
    .update_weight(update_first_layer),      // input:  update enable signal
    .start_state1(start_state1),             // input:  start state1 for [1]
    .delta_weight(delta_weight),             // input:  delta_weight for [6]
    .first_layer_weight(first_layer_weight), // output: printed out weight
    .end_state6(end_state6),                 // output: state6 is ended signal
    .start_multiply(start_multiply)          // output: signal for multiply
);

/* bias adding and take ReLu function */
bias1 #(
    .NWBITS(NWBITS), 
    .COUNT_BIT1(COUNT_BIT1)) BIAS1 (
    .clk(clk),                         // input:  external clk
    .reset_b(reset_b),                 // input:  asynchronous reset
    .update_bias(update_first_layer),  // input:  update data
    .add_bias(add_bias),               // input:  start add bias_and_relu
    .weighted_sum(weighted_sum),       // input:  weighted_sum of "weighted_sum1"
    .delta_bias(delta_bias),           // input:  delta_bias data
    .before_relu(before_relu),         // output: before_relu 
    .end_state1(end_state1)            // output: enable signal for state2
);

endmodule