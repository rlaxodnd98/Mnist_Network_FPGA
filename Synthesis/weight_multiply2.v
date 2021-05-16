module weighted_sum2 #(
    parameter NWBITS=16,
    parameter NHIDDEN=256,
    parameter COUNT_BIT1=10,       // int(log2(784)) + 1
    parameter COUNT_BIT2=8) (     // int(log2(256))
    input clk,
    input reset_b,
    input start_multiply,
    input signed [NWBITS+COUNT_BIT1-1:0] hidden_multiply,
    input signed [NWBITS-1:0] second_layer_weight,
    output signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] weighted_sum,
    output add_bias  
);

wire signed [NWBITS+NWBITS+COUNT_BIT1-1:0] partial_product;  // combinational multiply wire

assign partial_product = hidden_multiply * second_layer_weight;

accumulator2 #(
    .NWBITS(NWBITS), 
    .NHIDDEN(NHIDDEN), 
    .COUNT_BIT2(COUNT_BIT2), 
    .COUNT_BIT1(COUNT_BIT1)) ACCUMULATOR2 (
    .clk(clk),
    .reset_b(reset_b),
    .start_multiply(start_multiply),    
    .partial_product(partial_product),        // input:  multiply data
    .weighted_sum(weighted_sum),     // output: added data
    .add_bias(add_bias)
);

endmodule



/** accumulator2
 * 
 *  NHIDDEN data synchronously adder 
 */
module accumulator2 #(
    parameter NWBITS=16,
    parameter NHIDDEN=256,
    parameter COUNT_BIT2=8,      // int(log2(256))
    parameter COUNT_BIT1=10) (    // int(log2(784)) + 1
    input clk,
    input reset_b,
    input start_multiply,
    input signed [NWBITS+NWBITS+COUNT_BIT1-1:0] partial_product,
    output signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] weighted_sum,
    output add_bias
);

localparam WAIT        = 1'b0,     // waiting for start_multiply
           ACCUMULATE  = 1'b1;     // adding partial product of weighted_sum2

/* internal register declaration */
reg [COUNT_BIT2-1:0] counter;      // 0 ~ NHIDDEN-1
reg state;                         // 1bit state

/* output register declaration */
reg signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] weighted_sum_reg;
reg add_bias_reg;

always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        counter <= 8'd0;
        state <= WAIT;
        weighted_sum_reg <= 50'sd0;
    // state is WAIT
    end else if (state == WAIT) begin
        add_bias_reg <= 1'b0;
        if (start_multiply == 1'b1) begin  // accumulate enable signal
            state <= ACCUMULATE;            
            weighted_sum_reg <= partial_product;   // accumulate start
            counter <= 8'd1;     // start_counter 1
        end
    // state is ACCUMULATE
    end else if (state == ACCUMULATE) begin  // accumulate 
        weighted_sum_reg <= weighted_sum_reg + partial_product;  
        if (counter == NHIDDEN-1) begin
            state <= WAIT;
            add_bias_reg <= 1'b1;
            counter <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
        end
    end
end

assign weighted_sum = weighted_sum_reg;
assign add_bias = add_bias_reg;

endmodule

