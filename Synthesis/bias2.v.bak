module bias2 #(
    parameter NWBITS=16,
    parameter COUNT_BIT2=8,
    parameter COUNT_BIT1=10,
    parameter NUM=0) (     // initial bias number
    input clk,
    input reset_b,
    input update_bias,
    input add_bias,
    input signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] weighted_sum,
    input signed [NWBITS-1:0] delta_bias,
    output signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] output_neuron,
    output end_state2
);

localparam WAIT   = 1'b0,    // waiting for add_bias
           SECOND = 1'b1;    // end_state2 is high state

reg state;

reg signed [NWBITS-1:0] bias[0:0];                      // bias data
reg signed [NWBITS+NWBITS+COUNT_BIT1+COUNT_BIT2-1:0] output_neuron_reg; 
reg end_state2_reg;                                     // output: end_state2

/* initial bias data block */
initial begin
    if (NUM == 0) $readmemh("bias_memory2_0.txt", bias);
    if (NUM == 1) $readmemh("bias_memory2_1.txt", bias);
    if (NUM == 2) $readmemh("bias_memory2_2.txt", bias);
    if (NUM == 3) $readmemh("bias_memory2_3.txt", bias);
    if (NUM == 4) $readmemh("bias_memory2_4.txt", bias);
    if (NUM == 5) $readmemh("bias_memory2_5.txt", bias);
    if (NUM == 6) $readmemh("bias_memory2_6.txt", bias);
    if (NUM == 7) $readmemh("bias_memory2_7.txt", bias);
    if (NUM == 8) $readmemh("bias_memory2_8.txt", bias);
    if (NUM == 9) $readmemh("bias_memory2_9.txt", bias);
end


always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        bias[0] <= 16'sd0;             // bias data reset
        end_state2_reg <= 1'b0;
        state <= WAIT;
    end else if (state == WAIT) begin        
        if (update_bias) begin
            bias[0] <= bias[0] - delta_bias;
            end_state2_reg <= 1'b0;
        end else if (add_bias) begin
            output_neuron_reg <= weighted_sum + bias[0];
            end_state2_reg <= 1'b1;
            state <= SECOND;
        end
    end else if (state == SECOND) begin
        state <= WAIT;
        end_state2_reg <= 1'b0;
    end
end

/* output assignment */
assign end_state2 = end_state2_reg;
assign output_neuron = output_neuron_reg;    // we do not take ReLu function

endmodule