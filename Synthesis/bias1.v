/**
 * sequential bias adding and take ReLu function
 */
module bias1 #(
    parameter NWBITS=16,
    parameter COUNT_BIT1=10) (
    input clk,                         // external clk
    input reset_b,                     // asynchronous reset
    input update_bias,                 // update_bias state [6]
    input add_bias,                    // add_bias state [1]
    input signed [NWBITS+COUNT_BIT1-1:0] weighted_sum,  
    input signed [NWBITS-1:0] delta_bias,          // delta_bias value state[4]    
    output signed [NWBITS+COUNT_BIT1-1:0] before_relu,  //
    output end_state1
);

localparam WAIT  = 1'b0,   // WAITING FOR add_bias signal
           FIRST = 1'b1;   // state of end_state1 is high

reg state;
reg signed [NWBITS-1:0] bias;                         // bias data
reg signed [NWBITS+COUNT_BIT1-1:0] before_relu_reg;   // output : before_relu
reg end_state1_reg;                                   // output : end_state1


always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin          
        bias <= 16'sd0;         // initial bias value is 0 
        end_state1_reg <= 1'b0;
        state <= WAIT;   
    end else if (state == WAIT) begin
        if (update_bias) begin        // [6] UPDATE_FIRST_LAYER
            bias <= bias - delta_bias;    // differential bias
            end_state1_reg <= 1'b0;       
        end else if (add_bias) begin  // [1] FIRST_LAYER
            before_relu_reg <= weighted_sum + bias;
            end_state1_reg <= 1'b1;
            state <= FIRST;
        end
    end else if (state == FIRST) begin
        state <= WAIT;
        end_state1_reg <= 1'b0;
    end
end

/* output assignment*/
assign end_state1 = end_state1_reg;

/* before_relu output takes ReLu function */
assign before_relu = before_relu_reg;

endmodule
