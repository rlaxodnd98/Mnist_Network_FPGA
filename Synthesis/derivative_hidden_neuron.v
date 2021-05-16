/* this module calculate derivative_hidden_neuron
 * multiply derivative of ReLu
 * this module is created with generate statement,
 * so, NHIDDEN module is existed in Neural Network */
module derivative_hidden_neuron #(parameter NWBITS=16) (
    input clk,
    input reset_b,
    input enable_neuron,                //
    input signed [NWBITS-1:0] weight_pos,  // positive index weight
    input signed [NWBITS-1:0] weight_neg,  // negative index weight
    input hidden_neuron_isneg,                   // is hidden layer data neg?
    output signed [NWBITS:0] derivative_hidden_neuron  // weight_pos - weight_neg 
);

// output register declaration
reg signed [NWBITS:0] deriv;

// generate statement wire

// if hidden_layer data is negative, neuron active is 0,
// else, weight_pos - weight_neg is derivative_hidden_neuron 
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        deriv <= 17'sd0;
    end else begin
        if (enable_neuron) begin			
            if (hidden_neuron_isneg) begin  // is negative
                deriv <= 17'sd0;
            end else begin
                deriv <= weight_pos - weight_neg;
            end
        end
    end
end

assign derivative_hidden_neuron = deriv;

endmodule

