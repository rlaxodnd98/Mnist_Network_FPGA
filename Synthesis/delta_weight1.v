module delta_weight1 #(
    parameter NWBITS=16,
    parameter NPIXEL=784,
    parameter COUNT_BIT1=10) (
    input clk,
    input reset_b,
    input start_state6,                      // start_state6 signal 
    input pixel,                             // pixel_mul for [6] state
    input signed [NWBITS:0] derivative_hidden_neuron,  // calculated in [5] alre
    output signed [NWBITS-1:0] delta_weight    // 
);

localparam WAIT  = 1'b0,       // waiting for start_state6
           EXEC  = 1'b1;       // Executing delta_weight1 for update

reg state;
reg [COUNT_BIT1-1:0] counter;

reg signed [NWBITS-1:0] delta_weight_reg;   // delta_weight


/* divided 2^(-13) 8192 */
/* ex: 65536 -> 8      */
function signed [NWBITS-1:0] w_bit (
    input signed [NWBITS:0] x
);
    if (x < 0) begin
        w_bit = {12'b111111111111, x[NWBITS:NWBITS-3]} + 16'd1;
    end else begin
    	w_bit = {12'b000000000000, x[NWBITS:NWBITS-3]};
    end  
endfunction 

/* state diagram for delta_weight1 */
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        state <= WAIT;
        counter <= 10'd0;        
    end else if (state == WAIT) begin
        delta_weight_reg <= 16'd0;
        if (start_state6) begin
            state <= EXEC;  // 1clk delay for waiting derivative_hidden_neuron and pixel
            counter <= 10'd0;
        end
    end else if (state == EXEC) begin
        if (pixel) begin  // multiply process
            delta_weight_reg <= w_bit(derivative_hidden_neuron);
        end else begin
            delta_weight_reg <= 0;
        end
        if (counter == NPIXEL-1) begin
            counter <= 10'd0;
            state <= WAIT;
        end else begin
            counter <= counter + 10'd1;
        end
    end 
end

assign delta_weight = delta_weight_reg;

endmodule

/* */

module delta_bias1 #(parameter NWBITS=16) (
    input clk,
    input reset_b,
    input start_state6,
    input signed [NWBITS:0] derivative_hidden_neuron,
    output signed [NWBITS-1:0] delta_bias
);
/* divided 2^(-13) 8192 */
/* ex: 65536 -> 8      */
reg signed [NWBITS-1:0] delta_bias_reg;

function signed [NWBITS-1:0] w_bit (
    input signed [NWBITS:0] x
);
    if (x < 0) begin
        w_bit = {12'b111111111111, x[NWBITS:NWBITS-3]} + 16'd1; 
    end else begin
        w_bit = {12'b000000000000, x[NWBITS:NWBITS-3]};
    end 
endfunction 

always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        delta_bias_reg <= 16'sd0;
    end else begin
        delta_bias_reg <= 16'sd0;
        if (start_state6) begin
            delta_bias_reg <= w_bit(derivative_hidden_neuron);
        end
    end
end

assign delta_bias = delta_bias_reg;

endmodule
