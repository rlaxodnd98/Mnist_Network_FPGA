module weighted_sum1 #(
    parameter NWBITS=16,
    parameter NPIXEL=784,
    parameter COUNT_BIT1=10) (
    input clk,                  // external clk
    input reset_b,              // reset_b
    input start_multiply,       // start signal of weight_memory
    input pixel_multiply,       // pixel data of multiply
    input signed [NWBITS-1:0] first_layer_weight,
    output signed [NWBITS+COUNT_BIT1-1:0] weighted_sum,
    output add_bias
);

wire signed [NWBITS-1:0] partial_product;  // partial product

// if pixel_multiply = 1, partial_product = weights
// if pixel_multiply = 0, partial_product = 0
assign partial_product = pixel_multiply ? first_layer_weight : 16'sd0;

/**
 * add784_10 module instanciation
 * adding 784 clk, and assign weighted_sum 
 **/
accumulator1 #(
    .NWBITS(NWBITS), 
    .NPIXEL(NPIXEL), 
    .COUNT_BIT1(COUNT_BIT1)) ACCUMULATOR (
    .clk(clk),
    .reset_b(reset_b),
    .start_multiply(start_multiply),
    .partial_product(partial_product),
    .weighted_sum(weighted_sum),
    .add_bias(add_bias)
);

endmodule

