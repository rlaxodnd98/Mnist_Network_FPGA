/**
 * Implementation : this module transfer output_neuron to output_neuron_onehot
 *                  and compare with target_label_onehot.
 *                  If output_neuron is equal to target_label, matched signal
 *                  is 1'b1, otherwise, matched signal is 1'b0
 *
 *----------*/
module transfer_onehot_and_compare #(
    parameter OUT_BIT = 50, 
    parameter NOUT = 10) (
    input clk,
    input reset_b,
    input start_state3,
    input [NOUT-1:0] target_label_onehot,     // target_label one_hot
    input signed [OUT_BIT-1:0] output_neuron0,   
    input signed [OUT_BIT-1:0] output_neuron1,
    input signed [OUT_BIT-1:0] output_neuron2,
    input signed [OUT_BIT-1:0] output_neuron3,
    input signed [OUT_BIT-1:0] output_neuron4,
    input signed [OUT_BIT-1:0] output_neuron5,
    input signed [OUT_BIT-1:0] output_neuron6,
    input signed [OUT_BIT-1:0] output_neuron7,
    input signed [OUT_BIT-1:0] output_neuron8,
    input signed [OUT_BIT-1:0] output_neuron9,
    output [NOUT-1:0] output_neuron_onehot,  // output_neuron one_hot
    output [3:0] output_index,               
    output matched,                          // model expectation is matched?
    output end_state3
);

/**
 * Function name  : one_hot
 * 
 * Implementation : conversion 4bit digit data 
 *                  to one_hot vector
 *
 * Input  : [3:0] max = binary 4bit digit
 * Output : [9:0] one_hot = only 1bit data is high 
 */
function [NOUT-1:0] one_hot(
    input [3:0] max
);
begin
    case (max)
        0: one_hot = 10'b0000000001; 
        1: one_hot = 10'b0000000010;
        2: one_hot = 10'b0000000100;
        3: one_hot = 10'b0000001000;
        4: one_hot = 10'b0000010000;
        5: one_hot = 10'b0000100000;
        6: one_hot = 10'b0001000000;
        7: one_hot = 10'b0010000000;
        8: one_hot = 10'b0100000000;
        9: one_hot = 10'b1000000000;
        default: one_hot = 10'b0000000000;
    endcase     
end
endfunction 



/* state diagram constant */
localparam WAIT = 1'b0,         // WAITING for start_state3
           COMPARE = 1'b1;      // DO COMPARE state

/* internal register signal */
reg state;
reg [3:0] max;               // maximum index
reg [3:0] counter;           // state counter

/* output register declaration */
reg end_state3_reg;

wire signed [OUT_BIT-1:0] output_neuron[NOUT-1:0];

/* output_neuron assignment */
assign output_neuron[0] = output_neuron0;
assign output_neuron[1] = output_neuron1;
assign output_neuron[2] = output_neuron2;
assign output_neuron[3] = output_neuron3;
assign output_neuron[4] = output_neuron4;
assign output_neuron[5] = output_neuron5;
assign output_neuron[6] = output_neuron6;
assign output_neuron[7] = output_neuron7;
assign output_neuron[8] = output_neuron8;
assign output_neuron[9] = output_neuron9;

// total 8clk compare state diagram
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        state <= WAIT;
        max <= 4'b0;
        counter <= 4'b0;
    end else if (state == WAIT) begin  
        end_state3_reg <= 1'b0;
        if (start_state3) begin    // find maximum number of output_neuron
            state <= COMPARE;
            if (output_neuron[1] > output_neuron[0]) begin
            	max <= 4'd1;
            end else begin
            	max <= 4'd0;
            end
            counter <= 4'd2;
        end
    end else if (state == COMPARE) begin  
    	if (output_neuron[max] < output_neuron[counter]) begin
    		max <= counter;
    	end
    	if (counter == 4'd9) begin
    		state <= WAIT;
    		end_state3_reg <= 1'b1;
    	end else begin
    		counter <= counter + 4'd1;
    	end
    end
end

/* one_hot layer data output*/

// if target_label is equal to output neuron, matched is 1'b1
assign matched = (target_label_onehot == output_neuron_onehot) ? 1'b1 : 1'b0;
assign output_neuron_onehot = one_hot(max);
assign end_state3 = end_state3_reg;
assign output_index = max;

endmodule