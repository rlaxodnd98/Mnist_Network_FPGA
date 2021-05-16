/** 
 * If backpropagation process is needed,
 * start_pos and start_neg signal is active
 * and we calculate 
 * (learning rate) * (hidden_multiply)
 *  
 **/
module delta_weight2 #(
	parameter NWBITS=16,
	parameter NHIDDEN=256,
	parameter NHBITS=26,
	parameter COUNT_BIT2=8) (
    input clk,
    input reset_b,
    input start_pos,  // positive calculation
    input start_neg,  // negative calculation
    input signed [NHBITS-1:0] hidden_multiply,
    output signed [NWBITS-1:0] delta_weight
);

localparam [1:0] WAIT = 2'b00,   // module waiting for start signal
                 POS  = 2'b01,   // positive error state
                 NEG  = 2'b10;   // negative error state 

/* state variable */
reg [1:0] state;
reg [COUNT_BIT2-1:0] counter;


reg signed [NWBITS-1:0] delta_weight_reg;  // delta_weight 

/* divided 2^(-13) 8192 */
/* ex: 65536 -> 8       */
function signed [NWBITS-1:0] w_bit (
    input signed [NHBITS-1:0] x
);
    if (x < 0) begin
    	w_bit = {3'b111, x[NHBITS-1:NWBITS-3]} + 16'd1;
    end else begin
    	w_bit = {3'b000, x[NHBITS-1:NWBITS-3]};
    end

endfunction


/* state diagram for delta_weight2 */
always @(posedge clk, negedge reset_b) begin
	if (!reset_b) begin
		state <= WAIT;
		counter <= 8'd0;
	end else if (state == WAIT) begin         
		delta_weight_reg <= 16'sd0;
		if (start_pos) begin  // positive error
		    // learning rate == 1/8192 == 2^(-13)
			delta_weight_reg <= w_bit(hidden_multiply);
            state <= POS;          // state is POSITIVE weight
            counter <= 8'd1;
		end else if (start_neg) begin
		    // learning rate == 1/8192 == 2^(-13)
			delta_weight_reg <= -w_bit(hidden_multiply);
			state <= NEG;          // state is NEGATIVE weight
			counter <= 8'd1;
		end
	end else if (state == POS) begin
	    // learning rate == 1/8192 == 2^(-13)
		delta_weight_reg <= w_bit(hidden_multiply);
        if (counter == NHIDDEN-1) begin
        	counter <= 8'd0;
        	state <= WAIT;
        end else begin
        	counter <= counter + 8'd1;
        end
	end else if (state == NEG) begin
	    // learning rate == 1/8192 == 2^(-13)
		delta_weight_reg <= -w_bit(hidden_multiply);
		if (counter == NHIDDEN-1) begin
			counter <= 8'd0;
			state <= WAIT;
		end else begin
			counter <= counter + 8'd1;
		end
	end
end 

assign delta_weight = delta_weight_reg;

endmodule

/* */

module delta_bias2 #(parameter NWBITS=16) (
    input clk,
    input reset_b,
    input start_pos,      // positive calculation
    input start_neg,      // negative calculation
    output signed [NWBITS-1:0] delta_bias
);

reg signed [NWBITS-1:0] delta_bias_reg;

always @(posedge clk, negedge reset_b) begin
	if (!reset_b) begin
        delta_bias_reg <= 16'sd0;
	end else begin
	    delta_bias_reg <= 16'sd0;
        if (start_pos) begin
        	// learning rate == 1/8192 == 2^(-13)
        	delta_bias_reg <= 16'sd2;   // meaning 1/8192
        end	else if (start_neg) begin
        	delta_bias_reg <= -16'sd2;  // meaning -1/8192
        end
	end
end

assign delta_bias = delta_bias_reg;

endmodule