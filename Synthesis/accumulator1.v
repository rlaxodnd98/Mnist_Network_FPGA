module accumulator1 #(
    parameter NWBITS=16,
    parameter NPIXEL=784,
    parameter COUNT_BIT1=10) (
    input clk,                               // external clk
    input reset_b,                           // asynchronous reset
    input start_multiply,                    // start multiply
    input signed [NWBITS-1:0] partial_product,
    output signed [NWBITS+COUNT_BIT1-1:0] weighted_sum,
    output add_bias
);

localparam WAIT = 1'b0,  // waiting for start_multiply
           ADD  = 1'b1;  // accumulate 

/* variable declaration */
reg [COUNT_BIT1-1:0] counter;  // (0 ~ 783 counter)
reg state;              // 1bit state

/* output reg declaration */
reg signed [NWBITS+COUNT_BIT1-1:0] weighted_sum_reg;
reg add_bias_reg;


always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        counter <= 10'd0;
        state <= WAIT;
        weighted_sum_reg <= 26'sd0;
    end else if (state == WAIT) begin
        add_bias_reg <= 1'b0;
        if (start_multiply == 1'b1) begin
            state <= ADD;
            weighted_sum_reg <= 26'sd0 + partial_product;
            counter <= 10'd1;    // start counter 1
        end
    end else if (state == ADD) begin
        weighted_sum_reg <= weighted_sum_reg + partial_product;        
        if (counter == NPIXEL-1) begin
            state <= WAIT;
            add_bias_reg <= 1'b1;
            counter <= 10'd0;
        end else begin
            counter <= counter + 10'd1;
        end
    end
end

assign weighted_sum = weighted_sum_reg;
assign add_bias = add_bias_reg;

endmodule 